package routes

import (
  "encoding/json"
  "fmt"
  "github.com/gofiber/fiber/v3"
  "github.com/gofiber/utils/v2"
  "go.mongodb.org/mongo-driver/v2/bson"
  "rest/src/provider"
)

type AccountSyncRequestBody struct {
  Data    provider.UserStorage     `json:"data"`
  Changes *provider.StashedChanges `json:"changes"`
}

type AccountSubjectSemesterGradesPostBody struct {
  provider.GradesList `json:"grades"`
}

type AccountChoicePostBody struct {
  provider.Choice `json:"choice"`
}

type AccountSubjectAbiPredictionPostBody struct {
  Prediction *uint8 `json:"prediction"`
}

type AccountSemesterPostBody struct {
  Semester provider.Semester `json:"semester"`
}

type AccountSubjectPostBody struct {
  Settings *provider.SubjectSettings `json:"settings"`
}

type AccountSubjectsPostBody struct {
  Settings provider.SubjectSettingsMap `json:",inline"`
}

func (app AppEmbed) HandlePostAccountSync(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  // print body as string for debugging
  println("account sync request body:", string(ctx.Body()))

  var body AccountSyncRequestBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    fmt.Println(err.Error())
    fmt.Println(err)
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid request body")
  }

  // print body as json encoded for debugging
  bodyJson, _ := json.Marshal(body)
  println("account sync request body (json):", string(bodyJson))

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to find user")
  }

  mergedStorage := provider.MergeUserStorageAndChanges(user.UserStorage, body.Data, body.Changes, user.LastSync)

  // print merged storage as json encoded for debugging
  mergedStorageJson, _ := json.Marshal(mergedStorage)
  println("merged storage:", string(mergedStorageJson))

  err = app.Database.UpdateUserStorage(userId, mergedStorage, provider.IncludeAllUserStorageUpdate())
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to update user storage")
  }

  return ctx.JSON(mergedStorage)
}

func (app AppEmbed) HandlePostAccountSubjectSemesterGrades(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  var body AccountSubjectSemesterGradesPostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid request body")
  }

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to find user")
  }

  subjectParam := ctx.Params("subject")
  semesterParam := ctx.Params("semester")

  subjectId, err := utils.ParseUint8(subjectParam)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid subject id")
  }

  if user.UserStorage.Grades == nil {
    user.UserStorage.Grades = make(provider.SemesterSubjectGradesMap)
  }
  if user.UserStorage.Grades[semesterParam] == nil {
    user.UserStorage.Grades[semesterParam] = make(provider.SubjectGradesMap)
  }
  user.UserStorage.Grades[semesterParam][subjectId] = body.GradesList

  err = app.Database.UpdateUserStorage(userId, user.UserStorage, provider.IncludeUserStorageUpdate{IncludeGrades: true})
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to update user storage")
  }

  return ctx.SendStatus(fiber.StatusOK)
}

func (app AppEmbed) HandlePostAccountChoice(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  var body AccountChoicePostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid request body")
  }

  updateStorage := provider.UserStorage{
    Choice: &body.Choice,
  }

  err = app.Database.UpdateUserStorage(userId, updateStorage, provider.IncludeUserStorageUpdate{IncludeChoice: true})
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to update user storage")
  }

  return ctx.SendStatus(fiber.StatusOK)
}

func (app AppEmbed) HandlePostAccountSubjectAbiPrediction(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  var body AccountSubjectAbiPredictionPostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid request body")
  }

  subjectParam := ctx.Params("subject")

  subjectId, err := utils.ParseUint8(subjectParam)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid subject id")
  }

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to find user")
  }

  var abiPredictions = user.UserStorage.AbiPredictions
  if abiPredictions == nil {
    abiPredictions = make(provider.AbiPredictionMap)
  }
  if body.Prediction != nil {
    abiPredictions[subjectId] = *body.Prediction
  } else {
    delete(abiPredictions, subjectId)
  }

  updatedStorage := provider.UserStorage{
    AbiPredictions: abiPredictions,
  }

  err = app.Database.UpdateUserStorage(userId, updatedStorage, provider.IncludeUserStorageUpdate{IncludeAbiPredictions: true})
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to update user storage")
  }

  return ctx.SendStatus(fiber.StatusOK)
}

func (app AppEmbed) HandleDeleteAccount(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  err = app.Database.DeleteIdentities(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to delete user identities")
  }

  err = app.Database.DeleteUser(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to delete user")
  }

  err = app.Database.DeleteSessions(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to delete user sessions")
  }

  return ctx.SendStatus(fiber.StatusOK)
}

func (app AppEmbed) HandleGetAccountSessions(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  currentSessionJti := ctx.Get("Current-Session-ID", "")

  sessions, err := app.Database.FindAllSessionByUserId(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to retrieve user sessions")
  }

  var currentSessionId string
  for _, session := range sessions {
    if session.ActiveJti == currentSessionJti {
      currentSessionId = session.Id.Hex()
    }
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"sessions": sessions, "current_session_id": currentSessionId})
}

func (app AppEmbed) HandleDeleteAccountSession(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  sessionIdParam := ctx.Params("session")

  sessionId, err := bson.ObjectIDFromHex(sessionIdParam)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid session id")
  }

  err = app.Database.DeleteSessionById(sessionId, userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("failed to delete session")
  }

  return ctx.SendStatus(fiber.StatusOK)
}

func (app AppEmbed) HandlePostAccountSemester(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  var body AccountSemesterPostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid request body")
  }

  updateStorage := provider.UserStorage{
    Semester: &body.Semester,
  }

  err = app.Database.UpdateUserStorage(userId, updateStorage, provider.IncludeUserStorageUpdate{IncludeSemester: true})
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to update user storage")
  }

  return ctx.SendStatus(fiber.StatusOK)
}

func (app AppEmbed) HandlePostAccountSubjectSettings(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  var body AccountSubjectPostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid request body")
  }

  subjectParam := ctx.Params("subject")

  subjectId, err := utils.ParseUint8(subjectParam)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid subject id")
  }

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to find user")
  }

  var subjectSettings = user.UserStorage.SubjectSettings
  if subjectSettings == nil {
    subjectSettings = make(provider.SubjectSettingsMap)
  }
  if body.Settings == nil {
    delete(subjectSettings, subjectId)
  } else {
    subjectSettings[subjectId] = *body.Settings
  }

  updatedStorage := provider.UserStorage{
    SubjectSettings: subjectSettings,
  }

  err = app.Database.UpdateUserStorage(userId, updatedStorage, provider.IncludeUserStorageUpdate{IncludeSubjectSettings: true})
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to update user storage")
  }

  return ctx.SendStatus(fiber.StatusOK)
}

func (app AppEmbed) HandlePostAccountSubjectsSettings(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  var body AccountSubjectsPostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).SendString("Invalid request body")
  }

  updatedStorage := provider.UserStorage{
    SubjectSettings: body.Settings,
  }

  err = app.Database.UpdateUserStorage(userId, updatedStorage, provider.IncludeUserStorageUpdate{IncludeSubjectSettings: true})
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to update user storage")
  }

  return ctx.SendStatus(fiber.StatusOK)
}

func (app AppEmbed) HandleGetAccountExport(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).SendString("Invalid jwt token")
  }

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to find user")
  }

  sessions, err := app.Database.FindAllSessionByUserId(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to retrieve user sessions")
  }

  identities, err := app.Database.FindAllIdentitiesByUserId(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).SendString("Failed to retrieve user identities")
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"user_data": user, "sessions": sessions, "identities": identities})
}
