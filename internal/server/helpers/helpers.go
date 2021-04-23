package helpers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/rs/zerolog/log"
)

func SendError(c *fiber.Ctx, statusCode int, message string, err error) error {
	log.Err(err).Int("Code", statusCode).Msg(message)

	return c.Status(statusCode).JSON(&fiber.Map{
		"error": message,
	})
}
