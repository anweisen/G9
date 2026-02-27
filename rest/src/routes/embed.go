package routes

import (
	jwtware "github.com/gofiber/contrib/v3/jwt"
	"github.com/gofiber/fiber/v3"
	"go.mongodb.org/mongo-driver/v2/bson"
	"rest/src/provider"
)

type AppEmbed struct {
	Database provider.Database
}

func ExtractUserId(ctx fiber.Ctx) (provider.UserId, error) {
	jwt := jwtware.FromContext(ctx)
	sub, err := jwt.Claims.GetSubject()
	if err != nil {
		return bson.NilObjectID, err
	}

	userId, err := bson.ObjectIDFromHex(sub)
	return userId, err
}
