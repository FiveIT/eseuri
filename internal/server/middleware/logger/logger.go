package logger

import (
	"os"

	"github.com/FiveIT/template/internal/server/helpers"
	"github.com/gofiber/fiber/v2"
	"github.com/machinebox/graphql"
	"github.com/rs/zerolog"
)

func Middleware(graphqlClient *graphql.Client) func(*fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		logger := zerolog.
			New(os.Stderr).
			With().
			Timestamp().
			Str("hostname", c.Hostname()).
			Strs("ips", c.IPs()).
			Logger()

		c.Locals("logger", logger)

		if graphqlClient != nil {
			if helpers.ShouldShowGraphQLClientLogs(c) {
				graphqlClient.Log = func(s string) {
					logger.Debug().Str("where", "graphql").Msg(s)
				}
			} else {
				graphqlClient.Log = func(string) {}
			}
		}

		return c.Next()
	}
}
