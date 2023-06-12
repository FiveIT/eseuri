package helpers

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"github.com/FiveIT/eseuri/server/meta"
	"github.com/gofiber/fiber/v2"
	"github.com/machinebox/graphql"
)

type GraphQLRequestOptions struct {
	// Output is the structure the response is unmarshaled into.
	// If you don't need the query's result, it can be nil.
	Output  interface{}
	Context context.Context
	Headers map[string]string
	Vars    map[string]interface{}
	// Promote tells the function to add the specific Hasura headers
	// containing the admin secret and the backend permissions toggle.
	Promote bool
}

func (g *GraphQLRequestOptions) process() {
	if g == nil {
		//nolint:exhaustivestruct
		*g = GraphQLRequestOptions{}
	}

	if g.Context == nil {
		g.Context = context.Background()
	}

	if g.Promote {
		if g.Headers == nil {
			g.Headers = make(map[string]string)
		}

		g.Headers["X-Hasura-Admin-Secret"] = meta.HasuraAdminSecret
		g.Headers["X-Hasura-Use-Backend-Only-Permissions"] = "true"
	}
}

// GraphQLRequest does a GraphQL request with the given client. It unmarshals the response in the out parameter,
// and using the optional opts parameter it can also take a context, additional headers, and variables.
// Only the first options object is used!
func GraphQLRequest(c *graphql.Client, query string, opts ...GraphQLRequestOptions) error {
	var config *GraphQLRequestOptions
	if len(opts) != 0 {
		config = &opts[0]
	}

	config.process()

	req := graphql.NewRequest(query)

	for k, v := range config.Headers {
		req.Header.Set(k, v)
	}

	for k, v := range config.Vars {
		req.Var(k, v)
	}

	//nolint:wraperror
	return c.Run(config.Context, req, config.Output)
}

// TODO: Better error messages
func HandleGraphQLError(c *fiber.Ctx, err error) error {
	if errVal := err.Error(); strings.Contains(errVal, "graphql:") {
		if !strings.Contains(errVal, "server returned a non-200 status code") {
			return SendError(c, fiber.StatusBadRequest, "interogare invalidă a bazei de date", err)
		}
	}

	return fmt.Errorf("failed to communicate with the database: %w", err)
}

const headerShowGraphQLLogs = "X-Eseuri-Show-GraphQL-Logs"

// ShowGraphQLClientLogs sets a request header that will
// tell the application to enable logs for the GraphQL client.
func ShowGraphQLClientLogs(req *http.Request) {
	req.Header.Set(headerShowGraphQLLogs, "true")
}

// ShouldShowGraphQLClientLogs returns true if GraphQL
// logs should be enabled in the current context.
func ShouldShowGraphQLClientLogs(c *fiber.Ctx) bool {
	return c.Get(headerShowGraphQLLogs, "") == "true"
}
