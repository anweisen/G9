package routes

import (
  "context"
  "fmt"
  "github.com/gofiber/fiber/v3"
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

    jwtClaims := provider.CreateJwtClaims(user)
    jwt, err := provider.SignJwt(jwtClaims)
    if err != nil {
      fmt.Println(err)
      return ctx.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to sign jwt"})
    }

    publicUserProfile := provider.CreatePublicUserProfile(user)
    privateUserProfile := provider.CreatePrivateUserProfile(user)
    return ctx.Status(fiber.StatusOK).JSON(fiber.Map{"access_token": jwt, "user_profile": publicUserProfile, "private_profile": privateUserProfile})

  }

}
