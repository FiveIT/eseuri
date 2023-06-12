package routes

import (
	"strconv"

	"github.com/FiveIT/eseuri/server/meta/gqlqueries"
	"github.com/FiveIT/eseuri/server/server/helpers"
	"github.com/FiveIT/eseuri/server/server/middleware/auth"
	"github.com/gofiber/fiber/v2"
	"github.com/machinebox/graphql"
)

type userInfo struct {
	ID           int    `json:"id"`
	IsRegistered bool   `json:"isRegistered"`
	Role         string `json:"role"`
}

func fetchUserInfo(c *fiber.Ctx, client *graphql.Client) (*userInfo, error) {
	claims := c.Locals("claims").(auth.CustomClaims)

	var response gqlqueries.UserOutput

	if err := helpers.GraphQLRequest(client, gqlqueries.User, helpers.GraphQLRequestOptions{
		Output:  &response,
		Context: c.Context(),
		Headers: map[string]string{
			"X-Hasura-User-Id": strconv.Itoa(claims.UserID),
			"X-Hasura-Role":    claims.Role,
		},
		Vars: map[string]interface{}{
			"id": claims.UserID,
		},
		Promote: true,
	}); err != nil {
		return nil, helpers.HandleGraphQLError(c, err)
	}

	if len(response.Query) == 0 {
		return nil, helpers.SendError(c, fiber.StatusNotFound, "acest utilizator nu există", nil)
	}

	user := response.Query[0]

	return &userInfo{
		ID:           claims.UserID,
		IsRegistered: user.UpdatedAt != nil,
		Role:         user.Role,
	}, nil
}

func UserInfo(client *graphql.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		info, err := fetchUserInfo(c, client)
		if info == nil {
			return err
		}

		return c.JSON(info)
	}
}
