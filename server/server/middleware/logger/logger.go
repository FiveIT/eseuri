package logger

import (
	"io"
	"os"

	"github.com/FiveIT/eseuri/server/server/helpers"
	"github.com/gofiber/fiber/v2"
	"github.com/machinebox/graphql"
	"github.com/rs/zerolog"
)

// Middleware creates a middleware that adds to the context's local variables a
// logger that can be used inside subsequent middlewares or routes. It also sets
// a log function for the given GraphQL client, if the required header is set
// (see helpers.ShouldShowGraphQLClientLogs).
// The middleware creates a logger that writes to os.Stderr by default, but you
// can specify a different output by passing writers to the function. If you
// pass multiple writers, the log output will be written to all of them.
func Middleware(graphqlClient *graphql.Client, outputs ...io.Writer) func(*fiber.Ctx) error {
	var w io.Writer = os.Stderr
	if l := len(outputs); l == 1 {
		w = outputs[0]
	} else if l > 1 {
		w = io.MultiWriter(outputs...)
	}

	return func(c *fiber.Ctx) error {
		logger := zerolog.
			New(w).
			With().
			Timestamp().
			Str("userAgent", string(c.Context().UserAgent())).
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
