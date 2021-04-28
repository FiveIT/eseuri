package routes

import (
	"github.com/FiveIT/eseuri/internal/server/middleware/auth"
	"github.com/gofiber/fiber/v2"
)

func IsRegistered(c *fiber.Ctx) error {
	claims := c.Locals("claims").(auth.CustomClaims)

	return c.JSON(fiber.Map{
		"isRegistered": claims.IsRegistered,
	})
}
