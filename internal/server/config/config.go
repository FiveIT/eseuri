package config

import (
	"net/http"

	"github.com/FiveIT/template/internal/server/helpers"
	"github.com/gofiber/fiber/v2"
)

const bufferSize = 8192

var errorHandler = func(c *fiber.Ctx, e error) error {
	return helpers.SendError(c, http.StatusInternalServerError, "internal error", e)
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
