package config

import (
	"github.com/FiveIT/eseuri/internal/server/helpers"
	"github.com/gofiber/fiber/v2"
)

const bufferSize = 8192

// TODO: Better error messages
func errorHandler(c *fiber.Ctx, e error) error {
	if e.Error() == "Bad Request" {
		return helpers.SendError(c, fiber.StatusBadRequest, "invalid request body", nil)
	}

	return helpers.SendError(c, fiber.StatusInternalServerError, "internal error", e)
}

// Config returns the default server configuration.
func Config() fiber.Config {
	//nolint:exhaustivestruct
	return fiber.Config{
		// This is modified because it errors on longer authorization tokens
		ReadBufferSize: bufferSize,
		ErrorHandler:   errorHandler,
	}
}
