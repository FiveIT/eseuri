package auth

import (
	"github.com/FiveIT/eseuri/server/meta/gqlqueries"
	"github.com/FiveIT/eseuri/server/server/helpers"
	"github.com/gofiber/fiber/v2"
	"github.com/machinebox/graphql"
)

func AssertRegistration(client *graphql.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		claims := c.Locals("claims").(CustomClaims)

		if claims.IsRegistered {
			return c.Next()
		}

		var resp gqlqueries.UserOutput

		//nolint:exhaustivestruct
		if err := helpers.GraphQLRequest(client, gqlqueries.User, helpers.GraphQLRequestOptions{
			Output:  &resp,
			Context: c.Context(),
			Headers: map[string]string{
				fiber.HeaderAuthorization: c.Get(fiber.HeaderAuthorization),
			},
			Vars: map[string]interface{}{
				"id": claims.UserID,
			},
		}); err != nil {
			return helpers.HandleGraphQLError(c, err)
		}

		if resp.Query[0].UpdatedAt == nil {
			return helpers.SendError(c, fiber.StatusUnauthorized, "nu ești înregistrat", nil)
		}

		return c.Next()
	}
}
