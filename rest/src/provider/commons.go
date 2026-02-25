package provider

import (
	"go.mongodb.org/mongo-driver/v2/bson"
	"time"
)

func CreateUserAndIdentity(database Database, provider string, providerUserId string, name string, email string, picture string) (*User, *Identity, error) {
	user := User{
		Email:     email,
		Name:      name,
		Picture:   picture,
		CreatedAt: time.Now(),
	}

	userId, err := database.CreateUser(&user)
	if err != nil {
		return nil, nil, err
	}
	user.Id = *userId

	identity := Identity{
		Id:             bson.NilObjectID,
		UserId:         user.Id,
		Provider:       provider,
		ProviderUserId: providerUserId,
	}

	err = database.CreateIdentity(&identity)
	if err != nil {
		return nil, nil, err
	}

	return &user, &identity, nil
}

func CreatePublicUserProfile(user *User) PublicUserProfile {
	return PublicUserProfile{
		Id:      user.Id.Hex(),
		Name:    user.Name,
		Picture: user.Picture,
	}
}
