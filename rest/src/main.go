package main

import (
	jwtware "github.com/gofiber/contrib/v3/jwt"
	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/extractors"
	"os"
	"rest/src/provider"
	"rest/src/routes"
)

func main() {
	server := fiber.New()
	database := provider.NewMongoDatabase()

	embed := routes.AppEmbed{
		Database: database,
	}

	server.Post("/auth/exchange", embed.HandlePostAuthExchange)

	accountGroup := server.Group("/account", jwtware.New(jwtware.Config{
		SigningKey: jwtware.SigningKey{Key: provider.JwtSecretBytes},
		Extractor:  extractors.FromAuthHeader("Bearer"),
	}))
	accountGroup.Delete("", embed.HandleDeleteAccount)
	accountGroup.Post("/sync", embed.HandlePostAccountSync)
	accountGroup.Post("/grades/:subject/:semester", embed.HandlePostAccountSubjectSemesterGrades)
	accountGroup.Post("/abi-prediction/:subject", embed.HandlePostAccountSubjectAbiPrediction)
	accountGroup.Post("/choice", embed.HandlePostAccountChoice)

	bind, present := os.LookupEnv("BIND_ADDR")
	if !present {
		bind = ":5000"
	}

	err := server.Listen(bind)
	if err != nil {
		panic(err)
	}

}
