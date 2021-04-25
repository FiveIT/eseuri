package helpers

import (
	"net/http"

	"github.com/gofiber/fiber/v2"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func SendError(c *fiber.Ctx, statusCode int, message string, err error) error {
	logger, ok := c.Locals("logger").(zerolog.Logger)
	if !ok {
		logger = log.Logger
		logger.Err(err).Stack().Msg("context logger does not exist")
	}

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
