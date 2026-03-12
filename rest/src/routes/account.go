package routes

import (
  "encoding/json"
  "fmt"
  "github.com/gofiber/fiber/v3"
  "github.com/gofiber/utils/v2"
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

func (app AppEmbed) HandlePostAccountSync(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid jwt token"})
  }

  // print body as string for debugging
  println("account sync request body:", string(ctx.Body()))

  var body AccountSyncRequestBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    fmt.Println(err.Error())
    fmt.Println(err)
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
  }

  // print body as json encoded for debugging
  bodyJson, _ := json.Marshal(body)
  println("account sync request body (json):", string(bodyJson))

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to find user"})
  }

  mergedStorage := provider.MergeUserStorageAndChanges(user.UserStorage, body.Data, body.Changes, user.LastSync)

  // print merged storage as json encoded for debugging
  mergedStorageJson, _ := json.Marshal(mergedStorage)
  println("merged storage:", string(mergedStorageJson))

  err = app.Database.UpdateUserStorage(userId, mergedStorage, provider.IncludeAllUserStorageUpdate())
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to update user storage"})
  }

  return ctx.JSON(mergedStorage)
}

func (app AppEmbed) HandlePostAccountSubjectSemesterGrades(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid jwt token"})
  }

  var body AccountSubjectSemesterGradesPostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
  }

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to find user"})
  }

  subjectParam := ctx.Params("subject")
  semesterParam := ctx.Params("semester")

  subjectId, err := utils.ParseUint8(subjectParam)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid subject id"})
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
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to update user storage"})
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"status": "success"})
}

func (app AppEmbed) HandlePostAccountChoice(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid jwt token"})
  }

  var body AccountChoicePostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
  }

  updateStorage := provider.UserStorage{
    Choice: &body.Choice,
  }

  err = app.Database.UpdateUserStorage(userId, updateStorage, provider.IncludeUserStorageUpdate{IncludeChoice: true})
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to update user storage"})
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"status": "success"})
}

func (app AppEmbed) HandlePostAccountSubjectAbiPrediction(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid jwt token"})
  }

  var body AccountSubjectAbiPredictionPostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
  }

  subjectParam := ctx.Params("subject")

  subjectId, err := utils.ParseUint8(subjectParam)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid subject id"})
  }

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to find user"})
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
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to update user storage"})
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"status": "success"})
}

func (app AppEmbed) HandleDeleteAccount(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid jwt token"})
  }

  err = app.Database.DeleteIdentities(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to delete user identities"})
  }

  err = app.Database.DeleteUser(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to delete user"})
  }

  err = app.Database.DeleteSessions(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to delete user sessions"})
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"status": "success"})
}

func (app AppEmbed) HandleGetAccountSessions(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid jwt token"})
  }

  sessions, err := app.Database.FindAllSessionByUserId(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to retrieve user sessions"})
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"sessions": sessions})
}

func (app AppEmbed) HandlePostAccountSemester(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid jwt token"})
  }

  var body AccountSemesterPostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
  }

  updateStorage := provider.UserStorage{
    Semester: &body.Semester,
  }

  err = app.Database.UpdateUserStorage(userId, updateStorage, provider.IncludeUserStorageUpdate{IncludeSemester: true})
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to update user storage"})
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"status": "success"})
}

func (app AppEmbed) HandlePostAccountSubjectSettings(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid jwt token"})
  }

  var body AccountSubjectPostBody
  err = ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
  }

  subjectParam := ctx.Params("subject")

  subjectId, err := utils.ParseUint8(subjectParam)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid subject id"})
  }

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to find user"})
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
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to update user storage"})
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"status": "success"})
}

func (app AppEmbed) HandleGetAccountExport(ctx fiber.Ctx) error {
  userId, err := ExtractUserId(ctx)
  if err != nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid jwt token"})
  }

  user, err := app.Database.FindUserById(userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to find user"})
  }

  return ctx.Status(fiber.StatusOK).JSON(user)
}
