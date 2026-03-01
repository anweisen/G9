package routes

import (
  "context"
  "fmt"
  "github.com/gofiber/fiber/v3"
  "github.com/golang-jwt/jwt/v5"
  "go.mongodb.org/mongo-driver/v2/bson"
  "golang.org/x/oauth2"
  "golang.org/x/oauth2/google"
  "google.golang.org/api/idtoken"
  "os"
  "rest/src/provider"
)

type AuthExchangeRequestBody struct {
  Code        string `json:"code"`
  Provider    string `json:"provider"`
  RedirectUri string `json:"redirect_uri"`
  DeviceName  string `json:"device_name"`
}

type AuthRefreshRequestBody struct {
  RefreshToken string `json:"refresh_token"`
  DeviceName   string `json:"device_name"`
}

type AuthLogoutRequestBody struct {
  RefreshToken string `json:"refresh_token"`
}

var (
  googleOAuthConfig = &oauth2.Config{
    ClientID:     os.Getenv("GOOGLE_CLIENT_ID"),
    ClientSecret: os.Getenv("GOOGLE_CLIENT_SECRET"),
    RedirectURL:  "https://g9.anweisen.net/callback.html",
    Scopes:       []string{"profile", "email"},
    Endpoint:     google.Endpoint,
  }
)

func (app AppEmbed) HandlePostAuthExchange(ctx fiber.Ctx) error {
  body := new(AuthExchangeRequestBody)

  err := ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
  }

  println("code:", body.Code)
  println("provider:", body.Provider)

  switch body.Provider {
  default:
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "unsupported oauth provider"})

  case "google":
    println("exchanging code for token with redirect")
    googleOAuthConfig.RedirectURL = body.RedirectUri // potential security risk, should validate this against a whitelist of allowed redirect URIs
    token, err := googleOAuthConfig.Exchange(context.Background(), body.Code)
    fmt.Println(token)
    if err != nil {
      fmt.Println(err)
      return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "failed to exchange code for token"})
    }

    println("exchanged code for token")

    googleJwtString := token.Extra("id_token").(string)
    googleJwt, err := idtoken.Validate(ctx, googleJwtString, googleOAuthConfig.ClientID)
    if err != nil {
      fmt.Println(err)
      return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to validate id token"})
    }

    println("validated id token")

    email := googleJwt.Claims["email"].(string)
    name := googleJwt.Claims["name"].(string)
    picture := googleJwt.Claims["picture"].(string)
    googleId := googleJwt.Subject

    println("email:", email, "name:", name, "picture:", picture)
    println("retrieving identity for google id:", googleId)

    identity, err := app.Database.FindIdentityByProvider("google", googleId)
    if err != nil {
      fmt.Println("error while finding identity", err)
      return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to retrieve user identity"})
    }

    println("retrieved identity for google id:", googleId, "identity:", identity)

    var user *provider.User
    if identity != nil {
      println("identity found, retrieving user", identity)

      user, err = app.Database.FindUserById(identity.UserId)
      if err != nil {
        fmt.Println(err)
        return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to retrieve user"})
      }
      if user == nil {
        fmt.Println("user not found for identity:", identity)
        return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "user not found for identity"})
      }
    } else {
      print("identity not found, creating new")

      user, identity, err = provider.CreateUserAndIdentity(app.Database, "google", googleId, name, email, picture)
      if err != nil {
        fmt.Println(err)
        return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to create user and identity"})
      }
    }

    accessClaims := provider.CreateAccessJwtClaims(user.Id)
    accessJwt, err := provider.SignJwt(accessClaims)
    if err != nil {
      fmt.Println(err)
      return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to sign jwt"})
    }

    refreshClaims := provider.CreateRefreshJwtClaims(user.Id)
    refreshJwt, err := provider.SignJwt(refreshClaims)
    if err != nil {
      fmt.Println(err)
      return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to sign refresh jwt"})
    }

    _, err = provider.CreateSession(app.Database, identity, body.DeviceName, refreshClaims.ID, refreshClaims.ExpiresAt.Time)
    if err != nil {
      fmt.Println(err)
      return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to create session"})
    }

    publicUserProfile := provider.ConstructPublicUserProfile(user)
    privateUserProfile := provider.ConstructPrivateUserProfile(user)
    return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"access_token": accessJwt, "refresh_token": refreshJwt, "user_profile": publicUserProfile, "private_profile": privateUserProfile})
  }

}

func (app AppEmbed) HandlePostAuthRefresh(ctx fiber.Ctx) error {
  body := new(AuthRefreshRequestBody)
  err := ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
  }

  refreshToken, err := jwt.ParseWithClaims(body.RefreshToken, &provider.JwtClaims{}, func(token *jwt.Token) (interface{}, error) {
    if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
      return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
    }
    return provider.JwtSecretBytes, nil
  })
  if err != nil || !refreshToken.Valid {
    fmt.Println(err)
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "refresh token invalid or expired"})
  }

  claims := refreshToken.Claims.(*provider.JwtClaims)
  oldJti := claims.ID
  userIdString := claims.Subject
  userId, err := bson.ObjectIDFromHex(userIdString)

  session, err := app.Database.FindSessionByJti(oldJti, userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to retrieve session"})
  }
  if session == nil {
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "session not found"})
  }

  newAccessToken := provider.CreateAccessJwtClaims(userId)
  newRefreshToken := provider.CreateRefreshJwtClaims(userId)

  newAccessJwt, err := provider.SignJwt(newAccessToken)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to sign jwt"})
  }
  newRefreshJwt, err := provider.SignJwt(newRefreshToken)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to sign refresh jwt"})
  }

  err = app.Database.UpdateSession(session.Id, newRefreshToken.ExpiresAt.Time, newRefreshToken.ID, body.DeviceName)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to update session"})
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"access_token": newAccessJwt, "refresh_token": newRefreshJwt})
}

func (app AppEmbed) HandlePostAuthLogout(ctx fiber.Ctx) error {
  body := new(AuthLogoutRequestBody)
  err := ctx.Bind().Body(&body)
  if err != nil {
    return ctx.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
  }

  refreshToken, err := jwt.ParseWithClaims(body.RefreshToken, &provider.JwtClaims{}, func(token *jwt.Token) (interface{}, error) {
    if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
      return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
    }
    return provider.JwtSecretBytes, nil
  })
  if err != nil || !refreshToken.Valid {
    fmt.Println(err)
    return ctx.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "refresh token invalid or expired"})
  }

  claims := refreshToken.Claims.(*provider.JwtClaims)
  jti := claims.ID
  userIdString := claims.Subject
  userId, err := bson.ObjectIDFromHex(userIdString)

  err = app.Database.DeleteSessionByJti(jti, userId)
  if err != nil {
    return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to delete session"})
  }

  return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"status": "success"})
}
