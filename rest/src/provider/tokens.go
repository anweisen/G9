package provider

import (
	"github.com/golang-jwt/jwt/v5"
	"os"
	"time"
)

var (
	JwtSecret      = os.Getenv("JWT_SIGN_SECRET")
	JwtSecretBytes = []byte(JwtSecret)
)

type JwtClaims struct {
	jwt.RegisteredClaims
}

func SignJwt(claims JwtClaims) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signedToken, err := token.SignedString(JwtSecretBytes)

	return signedToken, err
}

func CreateJwtClaims(user *User) JwtClaims {
	return JwtClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   user.Id.Hex(),
			IssuedAt:  jwt.NewNumericDate(user.CreatedAt),
			ExpiresAt: jwt.NewNumericDate(user.CreatedAt.Add(24 * 7 * time.Hour)),
		},
	}
}
