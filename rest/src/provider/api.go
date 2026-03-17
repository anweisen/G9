package provider

import (
  "go.mongodb.org/mongo-driver/v2/bson"
  "time"
)

type Database interface {
  FindIdentityByProvider(provider string, providerUserId string) (*Identity, error)
  FindUserById(id UserId) (*User, error)
  FindSessionByJti(jti string, userId UserId) (*Session, error)
  FindAllSessionByUserId(userId UserId) ([]Session, error)

  CreateUser(user *User) (*UserId, error)
  CreateIdentity(identity *Identity) error
  CreateSession(session *Session) error

  UpdateUserStorage(userId UserId, storage UserStorage, include IncludeUserStorageUpdate) error
  UpdateSession(sessionId UserId, newExpiresAt time.Time, newJti string, newDeviceName string) error

  DeleteUser(userId UserId) error
  DeleteIdentities(userId UserId) error
  DeleteSessions(userId UserId) error
  DeleteSessionByJti(jti string, userId UserId) error
  DeleteSessionById(sessionId UserId, userId UserId) error
}

type User struct { // saved in database (users)
  Id          UserId    `json:"id" bson:"_id,omitempty"`
  Email       string    `json:"email" bson:"email"`
  Name        string    `json:"name" bson:"name"`
  Picture     string    `json:"picture" bson:"picture"`
  CreatedAt   time.Time `json:"created_at" bson:"created_at"`
  UserStorage `json:",inline" bson:",inline"`
}

type Identity struct { // stored in database (identities)
  Id             UserId `json:"id" bson:"_id,omitempty"`
  UserId         UserId `json:"user_id" bson:"user_id"`
  Provider       string `json:"provider" bson:"provider"`
  ProviderUserId string `json:"provider_user_id" bson:"provider_user_id"`
}

type Session struct { // stored in database (sessions)
  Id         UserId    `json:"id" bson:"_id,omitempty"`
  UserId     UserId    `json:"-" bson:"user_id"`
  IdentityId UserId    `json:"identity_id" bson:"identity_id"`
  ActiveJti  string    `json:"-" bson:"active_jti"`
  DeviceName string    `json:"device_name" bson:"device_name"`
  ExpiresAt  time.Time `json:"expires_at" bson:"expires_at"`
}

type PublicUserProfile struct { // returned to clients
  Id      string `json:"id"`
  Name    string `json:"name"`
  Picture string `json:"picture"`
}

type PrivateUserProfile struct { // in addition to public profile
  Email     string    `json:"email"`
  CreatedAt time.Time `json:"created_at"`
}

type UserStorage struct { // stored in database part of User (users)
  LastSync        *time.Time               `json:"last_sync" bson:"last_sync"`
  Choice          *Choice                  `json:"choice" bson:"choice"`
  Semester        *Semester                `json:"semester" bson:"semester"`
  UsesSlider      *bool                    `json:"uses_slider" bson:"uses_slider"`
  AbiPredictions  AbiPredictionMap         `json:"abi_predictions" bson:"abi_predictions"`
  Grades          SemesterSubjectGradesMap `json:"grades" bson:"grades"`
  SubjectSettings SubjectSettingsMap       `json:"subject_settings" bson:"subject_settings"`
  //Theme *uint8 `json:"theme" bson:"theme"`
}

type IncludeUserStorageUpdate struct {
  IncludeChoice          bool
  IncludeSemester        bool
  IncludeUsesSlider      bool
  IncludeAbiPredictions  bool
  IncludeGrades          bool
  IncludeSubjectSettings bool
}

func IncludeAllUserStorageUpdate() IncludeUserStorageUpdate {
  return IncludeUserStorageUpdate{
    IncludeChoice:          true,
    IncludeSemester:        true,
    IncludeUsesSlider:      true,
    IncludeAbiPredictions:  true,
    IncludeGrades:          true,
    IncludeSubjectSettings: true,
  }
}

type Choice struct {
  Lk                SubjectId  `json:"lk" bson:"lk"`
  Sg1               SubjectId  `json:"sg1" bson:"sg1"`
  Ntg1              SubjectId  `json:"ntg1" bson:"ntg1"`
  MintSg2           SubjectId  `json:"mint_sg2" bson:"mint_sg2"`
  Pug13             bool       `json:"pug13" bson:"pug13"`
  GeoWr             SubjectId  `json:"geo_wr" bson:"geo_wr"`
  KunstMusik        SubjectId  `json:"ku_mu" bson:"ku_mu"`
  Vk                *SubjectId `json:"vk,omitempty" bson:"vk,omitempty"`
  Seminar           SubjectId  `json:"sem" bson:"sem"`
  Profil12          *SubjectId `json:"profil12,omitempty" bson:"profil12,omitempty"`
  Profil13          *SubjectId `json:"profil13,omitempty" bson:"profil13,omitempty"`
  Abi4              SubjectId  `json:"abi4" bson:"abi4"`
  Abi5              SubjectId  `json:"abi5" bson:"abi5"`
  SubstituteDeutsch bool       `json:"sub_d" bson:"sub_d"`
  SubstituteMathe   bool       `json:"sub_m" bson:"sub_m"`
}

type GradeEntry struct {
  Grade uint8  `json:"g" bson:"g"`
  Type  uint8  `json:"t" bson:"t"`
  Date  string `json:"d" bson:"d"` // only date (year-month-day), no time, in ISO format
}

type SubjectSettings struct {
  Color *uint32 `json:"color" bson:"color"`
}

type StashedChanges struct {
  Choice          *StashedChoice             `json:"choice,omitempty"`
  Grades          *StashedGrades             `json:"grades,omitempty"`
  AbiPredictions  *StashedAbiPredictions     `json:"abi_predictions,omitempty"`
  Semester        *StashedSemester           `json:"semester,omitempty"`
  SubjectSettings *StashedSubjectSettingsMap `json:"subject_settings,omitempty"`
}

type StashedValueChange[T any] struct {
  At time.Time `json:"at"`
  To T         `json:"to"`
}

type StashedGrades = map[Semester]map[SubjectId]StashedSubjectGrades
type StashedSubjectGrades = StashedValueChange[GradesList]
type StashedChoice = StashedValueChange[Choice]
type StashedAbiPredictions = map[SubjectId]StashedSubjectAbiPrediction
type StashedSubjectAbiPrediction = StashedValueChange[uint8]
type StashedSemester = StashedValueChange[Semester]
type StashedSubjectSettingsMap = map[SubjectId]StashedSubjectSettings
type StashedSubjectSettings = StashedValueChange[*SubjectSettings]

type UserId = bson.ObjectID

type GradesList = []GradeEntry
type SubjectGradesMap = map[SubjectId]GradesList
type SemesterSubjectGradesMap = map[Semester]SubjectGradesMap

type SubjectSettingsMap = map[SubjectId]SubjectSettings

type AbiPredictionMap = map[SubjectId]uint8

type SubjectId = uint8
type Semester = string
