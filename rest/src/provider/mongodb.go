package provider

import (
  "context"
  "errors"
  "go.mongodb.org/mongo-driver/v2/bson"
  "go.mongodb.org/mongo-driver/v2/mongo"
  "go.mongodb.org/mongo-driver/v2/mongo/options"
  "os"
  "time"
)

type MongoDatabase struct {
  Context            context.Context
  Databae            *mongo.Database
  UserCollection     *mongo.Collection
  IdentityCollection *mongo.Collection
  SessionCollection  *mongo.Collection
}

func NewMongoDatabase() Database {
  opts := options.Client().ApplyURI(os.Getenv("MONGODB_URI"))
  client, err := mongo.Connect(opts)

  if err != nil {
    panic(err)
  }

  database := client.Database("g9")
  userCollection := database.Collection("users")
  identityCollection := database.Collection("identities")
  sessionCollection := database.Collection("sessions")

  //sessionTtlIndexModel := mongo.IndexModel{
  //  Keys: bson.D{{Key: "expires_at", Value: 1}},
  //  Options: options.Index().SetExpireAfterSeconds(0),
  //}

  println("MongoDB connected successfully -", client.NumberSessionsInProgress())

  return &MongoDatabase{
    Context:            context.Background(),
    Databae:            database,
    UserCollection:     userCollection,
    IdentityCollection: identityCollection,
    SessionCollection:  sessionCollection,
  }
}

func (database MongoDatabase) FindIdentityByProvider(provider string, providerUserId string) (*Identity, error) {
  var result Identity
  findOneResult := database.IdentityCollection.FindOne(database.Context, bson.M{"provider": provider, "provider_user_id": providerUserId})

  if errors.Is(findOneResult.Err(), mongo.ErrNoDocuments) {
    return nil, nil
  }

  err := findOneResult.Decode(&result)
  if err != nil {
    return nil, err
  }

  return &result, nil
}

func (database MongoDatabase) FindUserById(id bson.ObjectID) (*User, error) {
  var result User
  findOneResult := database.UserCollection.FindOne(database.Context, bson.M{"_id": id})
  if errors.Is(findOneResult.Err(), mongo.ErrNoDocuments) {
    return nil, nil
  }

  err := findOneResult.Decode(&result)
  if err != nil {
    return nil, err
  }

  return &result, nil
}

func (database MongoDatabase) FindSessionByJti(jti string, userId bson.ObjectID) (*Session, error) {
  var result Session
  findOneResult := database.SessionCollection.FindOne(database.Context, bson.M{"active_jti": jti, "user_id": userId})
  if errors.Is(findOneResult.Err(), mongo.ErrNoDocuments) {
    return nil, nil
  }

  err := findOneResult.Decode(&result)
  if err != nil {
    return nil, err
  }

  return &result, nil
}

func (database MongoDatabase) FindAllSessionByUserId(userId bson.ObjectID) ([]Session, error) {
  var results []Session
  cursor, err := database.SessionCollection.Find(database.Context, bson.M{"user_id": userId})
  if err != nil {
    return nil, err
  }

  err = cursor.All(database.Context, &results)
  if err != nil {
    return nil, err
  }
  _ = cursor.Close(database.Context)
  return results, nil
}

func (database MongoDatabase) CreateUser(user *User) (*UserId, error) {
  result, err := database.UserCollection.InsertOne(database.Context, user)
  if err != nil {
    return nil, err
  }

  insertedId := result.InsertedID.(UserId)
  return &insertedId, nil
}

func (database MongoDatabase) CreateIdentity(identity *Identity) error {
  _, err := database.IdentityCollection.InsertOne(database.Context, identity)
  return err
}

func (database MongoDatabase) CreateSession(session *Session) error {
  _, err := database.SessionCollection.InsertOne(database.Context, session)
  return err
}

func (database MongoDatabase) UpdateUserStorage(userId UserId, storage UserStorage) error {
  syncTime := time.Now()
  storage.LastSync = &syncTime
  update := bson.M{
    "$set": storage,
  }

  _, err := database.UserCollection.UpdateOne(database.Context, bson.M{"_id": userId}, update)
  return err
}

func (database MongoDatabase) UpdateSession(sessionId UserId, newExpiresAt time.Time, newJti string, newDeviceName string) error {
  update := bson.M{
    "$set": bson.M{
      "expires_at":  newExpiresAt,
      "active_jti":  newJti,
      "device_name": newDeviceName,
    },
  }

  _, err := database.SessionCollection.UpdateOne(database.Context, bson.M{"_id": sessionId}, update)
  return err
}

func (database MongoDatabase) DeleteUser(userId UserId) error {
  _, err := database.UserCollection.DeleteOne(database.Context, bson.M{"_id": userId})
  return err
}

func (database MongoDatabase) DeleteIdentities(userId UserId) error {
  _, err := database.IdentityCollection.DeleteMany(database.Context, bson.M{"user_id": userId})
  return err
}

func (database MongoDatabase) DeleteSessions(userId UserId) error {
  _, err := database.SessionCollection.DeleteMany(database.Context, bson.M{"user_id": userId})
  return err
}

func (database MongoDatabase) DeleteSessionByJti(jti string, userId UserId) error {
  _, err := database.SessionCollection.DeleteOne(database.Context, bson.M{"active_jti": jti, "user_id": userId})
  return err
}
