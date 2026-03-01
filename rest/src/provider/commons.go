package provider

import (
	"encoding/json"
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

func CreatePrivateUserProfile(user *User) PrivateUserProfile {
	return PrivateUserProfile{
		Email:     user.Email,
		CreatedAt: user.CreatedAt,
	}
}

func IsAfter(changeTime time.Time, lastSync *time.Time) bool {
	return true
	//if lastSync == nil {
	//	return true
	//}
	//return changeTime.After(*lastSync)
}

func MergeUserStorageAndChanges(existing UserStorage, update UserStorage, changes *StashedChanges, lastSync *time.Time) UserStorage {
	// Sync is called on every app start, we want to pull changes from the server (without overwriting existing data).
	// Because changes are instantly pushed to the server, one can assume that the server always has the most up-to-date data.
	// However, it is also called on signin, on first signin there is no existing data, so we need to push user data into the database.
	// If some changes were not pushed to the server yet (e.g, user lost internet connection), they are contained in the StashedChanges,
	// we want to apply them on top of the server data, so that they are not lost.

	println("changes:", changes)
	if changes != nil {
		if changes.Choice != nil {
			if IsAfter(changes.Choice.At, lastSync) {
				existing.Choice = &changes.Choice.To
			}
		}
		println("changes.Grade", changes.Grades)
		if changes.Grades != nil {
			for semester, subjectGradeChangesMap := range *changes.Grades {
				for subjectId, gradeChangesList := range subjectGradeChangesMap {
					//println("isAfter", IsAfter(gradeChangesList.At, lastSync), " at:", gradeChangesList.At.String(), " (", gradeChangesList.At.UnixMilli(), ")", " lastSync:", lastSync.String()+" (", lastSync.UnixMilli(), ")")
					if IsAfter(gradeChangesList.At, lastSync) {
						if existing.Grades == nil {
							existing.Grades = make(SemesterSubjectGradesMap)
						}
						if existing.Grades[semester] == nil {
							existing.Grades[semester] = make(SubjectGradesMap)
						}
						existing.Grades[semester][subjectId] = gradeChangesList.To
						println("applied grade change for semester", semester, "subject", subjectId, "new grades list:", gradeChangesList.To)
					}
				}
			}
		}
		if changes.AbiPredictions != nil {
			for subjectId, predictionChangeList := range *changes.AbiPredictions {
				if IsAfter(predictionChangeList.At, lastSync) {
					if existing.AbiPredictions == nil {
						existing.AbiPredictions = make(AbiPredictionMap)
					}
					existing.AbiPredictions[subjectId] = predictionChangeList.To
					println("applied abi prediction change for subject", subjectId, "new prediction:", predictionChangeList.To)
				}
			}
		}
		if changes.Semester != nil {
			if IsAfter(changes.Semester.At, lastSync) {
				existing.Semester = &changes.Semester.To
				println("applied semester change, new semester:", changes.Semester.To)
			}
		}
	}

	var mergedGrades SemesterSubjectGradesMap
	if existing.Grades == nil && update.Grades != nil {
		mergedGrades = update.Grades
	} else if existing.Grades != nil && update.Grades == nil {
		mergedGrades = existing.Grades
	} else if existing.Grades != nil && update.Grades != nil {
		// Server-side existing grades are more up to date, apply them on top of the client-side grades
		mergedGrades = update.Grades
		for semester, existingSubjectGradeMap := range existing.Grades {
			if mergedGrades[semester] == nil {
				mergedGrades[semester] = existingSubjectGradeMap // No client-side grades for this semester, use all server-side grades
			} else {
				for subjectId, existingGradesList := range existingSubjectGradeMap {
					if mergedGrades[semester][subjectId] == nil {
						mergedGrades[semester][subjectId] = existingGradesList // No client-side grades for this subject, use all server-side grades
					} else {
						// TODO: Merge the two grade lists, preferring server-side grades in case of duplicates
						// clientGradesList := mergedGrades[semester][subjectId]
						mergedGrades[semester][subjectId] = existingGradesList // For now only use server-side grades, ignoring client-side grades, pushing deletions
					}
				}
			}
		}
	}

	// print existing and update abi predictions for debugging as json encoded
	existingAbiPredictionsJson, _ := json.Marshal(existing.AbiPredictions)
	updateAbiPredictionsJson, _ := json.Marshal(update.AbiPredictions)
	println("")
	println("existing abi predictions:", string(existingAbiPredictionsJson))
	println("update abi predictions:", string(updateAbiPredictionsJson))

	var mergedAbiPredictions AbiPredictionMap
	if existing.AbiPredictions != nil && update.AbiPredictions == nil {
		mergedAbiPredictions = existing.AbiPredictions
	} else if existing.AbiPredictions == nil && update.AbiPredictions != nil {
		mergedAbiPredictions = update.AbiPredictions
	} else if existing.AbiPredictions != nil && update.AbiPredictions != nil {
		// Server-side existing predictions are more up to date, apply them on top of the client-side predictions
		mergedAbiPredictions = update.AbiPredictions
		for subjectId, prediction := range existing.AbiPredictions {
			mergedAbiPredictions[subjectId] = prediction
		}
	}

	// print merged abi predictions for debugging as json encoded
	mergedAbiPredictionsJson, _ := json.Marshal(mergedAbiPredictions)
	println("merged abi predictions:", string(mergedAbiPredictionsJson))

	// Server-side data is more up to date, prefer them
	var updatedChoice *Choice
	if existing.Grades != nil {
		updatedChoice = existing.Choice
	} else {
		updatedChoice = update.Choice
	}

	var updatedSemester Semester
	if existing.Semester != nil && *existing.Semester != "" {
		updatedSemester = *existing.Semester
	} else {
		updatedSemester = *update.Semester
	}

	var updatedUsesSlider bool
	if existing.UsesSlider != nil {
		updatedUsesSlider = *existing.UsesSlider
	} else {
		updatedUsesSlider = *update.UsesSlider
	}

	//var updatedTheme uint8
	//if existing.Theme != nil {
	//	updatedTheme = *existing.Theme
	//} else {
	//	updatedTheme = *update.Theme
	//}

	newStorage := UserStorage{
		Semester:   &updatedSemester,
		UsesSlider: &updatedUsesSlider,
		//Theme: &updatedTheme,
		Choice:         updatedChoice,
		AbiPredictions: mergedAbiPredictions,
		Grades:         mergedGrades,
	}
	return newStorage
}
