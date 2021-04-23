package auth

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/FiveIT/template/internal/meta"
	"github.com/FiveIT/template/internal/server/helpers"
	jwt "github.com/form3tech-oss/jwt-go"
	"github.com/gofiber/fiber/v2"
	jwtware "github.com/gofiber/jwt/v2"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

type jwtCredentials struct {
	Key string `json:"key"`
}

type CustomClaims struct {
	UserID int
	Role   string
}

func (c *CustomClaims) MarshalZerologObject(z *zerolog.Event) {
	z.
		Int("userID", c.UserID).
		Str("role", c.Role)
}

const (
	hasuraNamespace = "https://hasura.io/jwt/claims"
	eseuriNamespace = "https://eseuri.com"
)

//nolint:exhaustivestruct
func Middleware() func(*fiber.Ctx) error {
	var (
		creds jwtCredentials
		err   error
	)

	if err = json.NewDecoder(strings.NewReader(meta.HasuraJWTSecret)).Decode(&creds); err != nil {
		log.Fatal().Err(err).Msg("failed to get auth middleware due to JWT credentials unmarshal error")
	}

	key, err := jwt.ParseRSAPublicKeyFromPEM([]byte(creds.Key))
	if err != nil {
		log.Fatal().Err(err).Msg("failed to get auth middleware due to failure in parsing public key from PEM")
	}

	return jwtware.New(jwtware.Config{
		SigningMethod: "RS256",
		SigningKey:    key,
		SuccessHandler: func(c *fiber.Ctx) error {
			logger := c.Locals("logger").(zerolog.Logger)

			claims := c.Locals("user").(*jwt.Token).Claims
			if err := claims.Valid(); err != nil {
				return helpers.SendError(c, http.StatusUnauthorized, "invalid claims", err)
			}

			user := claims.(jwt.MapClaims)

			logger.Debug().Fields(user).Msg("claims")

			eseuri := user[eseuriNamespace].(map[string]interface{})
			if !eseuri["hasCompletedRegistration"].(bool) {
				return helpers.SendError(c, http.StatusUnauthorized, "unregistered user", nil)
			}

			hasura := user[hasuraNamespace].(map[string]interface{})

			custom := &CustomClaims{}
			custom.Role = hasura["X-Hasura-Default-Role"].(string)
			custom.UserID, _ = strconv.Atoi(hasura["X-Hasura-User-Id"].(string))

			logger.Debug().EmbedObject(custom).Msg("unmarshaled custom claims")

			c.Locals("claims", claims)

			return c.Next()
		},
		ErrorHandler: func(c *fiber.Ctx, e error) error {
			return helpers.SendError(c, http.StatusUnauthorized, "invalid or expired token", e)
		},
	})
}