package provider

import (
  "github.com/golang-jwt/jwt/v5"
  "github.com/google/uuid"
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

func CreateAccessJwtClaims(userId UserId) JwtClaims {
  return JwtClaims{
    RegisteredClaims: jwt.RegisteredClaims{
      Subject:   userId.Hex(),
      IssuedAt:  jwt.NewNumericDate(time.Now()),
      ExpiresAt: jwt.NewNumericDate(time.Now().Add(1 * time.Hour)),
    },
  }
}

func CreateRefreshJwtClaims(userId UserId) JwtClaims {
  // refresh tokens are valid for 3 months (90 days), a rather long time for refresh tokens,
  // our main priority is to minimize the need for users to re-authenticate and improve user experience.
  // also, refresh tokens can be revoked before their expiration (jti stored in db)
  return JwtClaims{
    RegisteredClaims: jwt.RegisteredClaims{
      Subject:   userId.Hex(),
      ID:        uuid.NewString(),
      IssuedAt:  jwt.NewNumericDate(time.Now()),
      ExpiresAt: jwt.NewNumericDate(time.Now().Add(3 * 30 * 24 * time.Hour)),
    },
  }
}
