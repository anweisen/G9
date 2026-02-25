package main

import (
	"github.com/gofiber/fiber/v3"
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

	bind, present := os.LookupEnv("BIND_ADDR")
	if !present {
		bind = ":5000"
	}

	err := server.Listen(bind)
	if err != nil {
		panic(err)
	}

}
