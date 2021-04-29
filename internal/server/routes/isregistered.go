package routes

import (
	"github.com/FiveIT/eseuri/internal/meta/gqlqueries"
	"github.com/FiveIT/eseuri/internal/server/helpers"
	"github.com/FiveIT/eseuri/internal/server/middleware/auth"
	"github.com/gofiber/fiber/v2"
	"github.com/machinebox/graphql"
)

func resp(isRegistered bool) fiber.Map {
	return fiber.Map{
		"isRegistered": isRegistered,
	}
}

func IsRegistered(client *graphql.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		claims := c.Locals("claims").(auth.CustomClaims)

		if claims.IsRegistered {
			return c.JSON(resp(true))
		}

		var user gqlqueries.UserOutput

		//nolint:exhaustivestruct
		if err := helpers.GraphQLRequest(client, gqlqueries.User, helpers.GraphQLRequestOptions{
			Output:  &user,
			Context: c.Context(),
			Headers: map[string]string{
				fiber.HeaderAuthorization: c.Get(fiber.HeaderAuthorization),
			},
		}); err != nil {
			return helpers.HandleGraphQLError(c, err)
		}

		return c.JSON(resp(user.Query[0].UpdatedAt != nil))
	}
}
