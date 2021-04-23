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
	Type string `json:"type"`
	Key  string `json:"key"`
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

	return jwtware.New(jwtware.Config{
		SigningMethod: creds.Type,
		SigningKey:    creds.Key,
		SuccessHandler: func(c *fiber.Ctx) error {
			logger := c.Locals("logger").(zerolog.Logger)

			user := c.Locals("user").(jwt.MapClaims)

			logger.Debug().Fields(user).Msg("claims")

			eseuri := user[eseuriNamespace].(map[string]interface{})
			if !eseuri["hasCompletedRegistration"].(bool) {
				return helpers.SendError(c, http.StatusUnauthorized, "unregistered user", nil)
			}

			hasura := user[hasuraNamespace].(map[string]interface{})

			claims := CustomClaims{}
			claims.Role = hasura["X-Hasura-Default-Role"].(string)
			claims.UserID, _ = strconv.Atoi(hasura["X-Hasura-User-Id"].(string))

			logger.Debug().EmbedObject(&claims).Msg("unmarshaled custom claims")

			c.Locals("claims", claims)

			return c.Next()
		},
		ErrorHandler: func(c *fiber.Ctx, e error) error {
			return helpers.SendError(c, http.StatusUnauthorized, "invalid or expired token", e)
		},
	})
}
