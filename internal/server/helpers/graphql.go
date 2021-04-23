package helpers

import (
	"context"
	"log"
	"net/http"
	"strings"

	"github.com/FiveIT/template/internal/meta"
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
	// Log tells the function to add a logger function to the client.
	// By default it adds a simple log.Println:
	//	c.Log = func (s string) { log.Println(s) }
	// Specifying LogFn overrides this setting.
	Log bool
	// LogFn is the function used by the client to log to console.
	LogFn func(string)
}

func (g GraphQLRequestOptions) process() GraphQLRequestOptions {
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

	if g.LogFn == nil && g.Log {
		g.LogFn = func(s string) {
			log.Println(s)
		}
	}

	return g
}

func (g *GraphQLRequestOptions) setLogFn(c *graphql.Client) (bool, func(string)) {
	if g.LogFn != nil {
		prevFn := c.Log
		c.Log = g.LogFn

		return true, prevFn
	}

	return false, nil
}

// GraphQLRequest does a GraphQL request with the given client. It unmarshals the response in the out parameter,
// and using the optional opts parameter it can also take a context, additional headers, and variables.
// Only the first options object is used!
func GraphQLRequest(c *graphql.Client, query string, opts ...GraphQLRequestOptions) error {
	//nolint:exhaustivestruct
	config := GraphQLRequestOptions{}
	if len(opts) != 0 {
		config = opts[0]
	}

	config = config.process()

	hasCustomLog, prevLogFn := config.setLogFn(c)

	req := graphql.NewRequest(query)

	for k, v := range config.Headers {
		req.Header.Set(k, v)
	}

	for k, v := range config.Vars {
		req.Var(k, v)
	}

	err := c.Run(config.Context, req, config.Output)

	if hasCustomLog {
		c.Log = prevLogFn
	}

	//nolint:wrapcheck
	return err
}

func HandleGraphQLError(c *fiber.Ctx, err error) error {
	if errVal := err.Error(); strings.Contains(errVal, "graphql: ") {
		if !strings.Contains(errVal, "server returned a non-200 status code") {
			return SendError(c, http.StatusBadRequest, "eroare la interogarea bazei de date: "+err.Error(), err)
		}
	}

	return SendError(c, http.StatusInternalServerError, "a aparut o eroare la conectarea cu baza de date", err)
}

const showGQLLogsHeaderKey = "X-Eseuri-Show-GraphQL-Logs"

// ShowGraphQLClientLogs sets a request header that will
// tell the application to enable logs for the GraphQL client.
func ShowGraphQLClientLogs(req *http.Request) {
	req.Header.Set(showGQLLogsHeaderKey, "true")
}

// ShouldShowGraphQLClientLogs returns true if GraphQL
// logs should be enabled in the current context.
func ShouldShowGraphQLClientLogs(c *fiber.Ctx) bool {
	return c.Get(showGQLLogsHeaderKey, "") == "true"
}
