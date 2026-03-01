package provider

import (
	"go.mongodb.org/mongo-driver/v2/bson"
	"time"
)

type Database interface {
	FindIdentityByProvider(provider string, providerUserId string) (*Identity, error)
	FindUserById(id UserId) (*User, error)

	CreateUser(user *User) (*UserId, error)
	CreateIdentity(identity *Identity) error

	UpdateUserStorage(userId UserId, storage UserStorage) error

	DeleteUser(userId UserId) error
	DeleteIdentities(userId UserId) error
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
	LastSync   *time.Time `json:"last_sync" bson:"last_sync"`
	Choice     *Choice    `json:"choice,omitempty" bson:"choice,omitempty"`
	Semester   *Semester  `json:"semester,omitempty" bson:"semester,omitempty"`
	UsesSlider *bool      `json:"uses_slider,omitempty" bson:"uses_slider,omitempty"`
	//Theme *uint8 `json:"theme,omitempty" bson:"theme,omitempty"`
	AbiPredictions AbiPredictionMap         `json:"abi_predictions,omitempty" bson:"abi_predictions,omitempty"`
	Grades         SemesterSubjectGradesMap `json:"grades,omitempty" bson:"grades,omitempty"`
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

type StashedChanges struct {
	Choice         *StashedChoice         `json:"choice,omitempty"`
	Grades         *StashedGrades         `json:"grades,omitempty"`
	AbiPredictions *StashedAbiPredictions `json:"abi_predictions,omitempty"`
	Semester       *StashedSemester       `json:"semester,omitempty"`
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

type UserId = bson.ObjectID

type GradesList = []GradeEntry
type SubjectGradesMap = map[SubjectId]GradesList
type SemesterSubjectGradesMap = map[Semester]SubjectGradesMap

type AbiPredictionMap = map[SubjectId]uint8

type SubjectId = uint8
type Semester = string
