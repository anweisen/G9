package provider

import (
	"go.mongodb.org/mongo-driver/v2/bson"
	"time"
)

type UserId = bson.ObjectID

type Database interface {
	FindIdentityByProvider(provider string, providerUserId string) (*Identity, error)
	FindUserById(id UserId) (*User, error)

	CreateUser(user *User) (*UserId, error)
	CreateIdentity(identity *Identity) error
}

type User struct { // saved in database (users)
	Id        UserId    `json:"id" bson:"_id,omitempty"`
	Email     string    `json:"email" bson:"email"`
	Name      string    `json:"name" bson:"name"`
	Picture   string    `json:"picture" bson:"picture"`
	CreatedAt time.Time `json:"created_at" bson:"created_at"`
}

type Identity struct { // saved in database (identities)
	Id             UserId `json:"id" bson:"_id,omitempty"`
	UserId         UserId `json:"user_id" bson:"user_id"`
	Provider       string `json:"provider" bson:"provider"`
	ProviderUserId string `json:"provider_user_id" bson:"provider_user_id"`
}

type PublicUserProfile struct { // returned to clients
	Id      string `json:"id"`
	Name    string `json:"name"`
	Picture string `json:"picture"`
}
