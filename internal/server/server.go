package server

import (
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"

	"github.com/FiveIT/eseuri/internal/meta"
	"github.com/FiveIT/eseuri/internal/meta/gqlqueries"
	"github.com/FiveIT/eseuri/internal/mime"
	"github.com/FiveIT/eseuri/internal/server/config"
	"github.com/FiveIT/eseuri/internal/server/helpers"
	"github.com/FiveIT/eseuri/internal/server/middleware/auth"
	"github.com/FiveIT/eseuri/internal/server/middleware/logger"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
	"github.com/rs/zerolog"
)

func New() *fiber.App {
	graphqlClient := graphql.NewClient(meta.HasuraEndpoint + "/v1/graphql")
	client := tika.NewClient(nil, meta.TikaEndpoint)

	app := fiber.New(config.Config())

	var routes fiber.Router = app
	if meta.IsNetlify {
		routes = app.Group(meta.FunctionsBasePath)
	}

	//nolint:exhaustivestruct
	routes.Use(recover.New(recover.Config{
		EnableStackTrace: true,
	}))

	//nolint:exhaustivestruct
	routes.Use(cors.New(cors.Config{
		AllowOrigins: meta.URL(),
	}))

	routes.Use(logger.Middleware(graphqlClient))
	routes.Use(auth.Middleware())

	//nolint:exhaustivestruct
	routes.Post("/upload", func(c *fiber.Ctx) (err error) {
		logger := c.Locals("logger").(zerolog.Logger)

		workInput := &helpers.WorkFormInput{}

		// Va trece de eroarea asta chiar daca nu sunt prezente toate campurile formularului
		if err := c.BodyParser(workInput); err != nil {
			return helpers.SendError(c, http.StatusBadRequest, "couldn't parse form", err)
		}

		if workInput.File == nil {
			return helpers.SendError(c, http.StatusBadRequest, "file was not found in form", nil)
		}

		file, err := workInput.File.Open()
		if err != nil {
			return helpers.SendError(c, http.StatusBadRequest, "couldn't open form content file", err)
		}

		m, err := client.Detect(c.Context(), file)
		if err != nil {
			return fmt.Errorf("tika failed to detect MIME-type: %w", err)
		}

		_, err = file.Seek(0, io.SeekStart)
		if err != nil {
			return fmt.Errorf("failed to seek file to beginning: %w", err)
		}

		var body string

		switch m {
		case mime.DOC, mime.DOCX, mime.RTF, mime.ODT:
			body, err = client.Parse(c.Context(), file)
			if err != nil {
				return fmt.Errorf("tika failed to parse: %w", err)
			}
		case mime.TXT:
			s := &strings.Builder{}
			_, err = io.Copy(s, file)
			if err != nil {
				return fmt.Errorf("failed to copy form file: %w", err)
			}
			body = s.String()
		default:
			return helpers.SendError(c, http.StatusBadRequest, "invalid form content file type", nil)
		}

		claims := c.Locals("claims").(auth.CustomClaims)

		var work gqlqueries.InsertWorkOutput
		workOpts := helpers.GraphQLRequestOptions{
			Output:  &work,
			Context: c.Context(),
			Headers: map[string]string{
				"X-Hasura-Role":    claims.Role,
				"X-Hasura-User-Id": strconv.Itoa(claims.UserID),
			},
			Vars: map[string]interface{}{
				"content":            body,
				"requestedTeacherID": nil,
			},
			Promote: true,
		}
		if workInput.RequestedTeacherID != 0 {
			workOpts.Vars["requestedTeacherID"] = workInput.RequestedTeacherID
		}

		if err = helpers.GraphQLRequest(graphqlClient, gqlqueries.InsertWork, workOpts); err != nil {
			return helpers.HandleGraphQLError(c, err)
		}

		logger.Debug().Int("workID", work.Query.ID).Msg("work inserted successfully")

		query, ok := gqlqueries.InsertWorkSupertype[workInput.Type]
		if !ok {
			return helpers.SendError(c, http.StatusBadRequest, fmt.Sprintf("invalid work type %q", workInput.Type), nil)
		}

		supertypeOpts := helpers.GraphQLRequestOptions{
			Context: c.Context(),
			Vars: map[string]interface{}{
				"workID":    work.Query.ID,
				"subjectID": workInput.SubjectID,
			},
			Promote: true,
		}
		if err = helpers.GraphQLRequest(graphqlClient, query, supertypeOpts); err != nil {
			return helpers.HandleGraphQLError(c, err)
		}

		return c.SendStatus(http.StatusCreated)
	})

	return app
}
