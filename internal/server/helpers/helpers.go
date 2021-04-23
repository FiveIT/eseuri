package helpers

import (
	"net/http"

	"github.com/gofiber/fiber/v2"
	"github.com/rs/zerolog"
)

func SendError(c *fiber.Ctx, statusCode int, message string, err error) error {
	logger := c.Locals("logger").(zerolog.Logger)

	var ev *zerolog.Event
	if statusCode >= http.StatusInternalServerError {
		ev = logger.Error()
	} else {
		ev = logger.Info()
	}

	ev.Err(err).Int("code", statusCode).Msg(message)

	return c.Status(statusCode).JSON(&fiber.Map{
		"error": message,
	})
}
