package auth

import (
	"github.com/FiveIT/eseuri/internal/server/helpers"
	"github.com/gofiber/fiber/v2"
)

func AssertRegistration(c *fiber.Ctx) error {
	claims := c.Locals("claims").(CustomClaims)

	if !claims.IsRegistered {
		return helpers.SendError(c, fiber.StatusUnauthorized, "unregistered user", nil)
	}

	return c.Next()
}
