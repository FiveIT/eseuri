package routes

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"

	"github.com/FiveIT/eseuri/internal/meta/gqlqueries"
	"github.com/FiveIT/eseuri/internal/mime"
	"github.com/FiveIT/eseuri/internal/server/helpers"
	"github.com/FiveIT/eseuri/internal/server/middleware/auth"
	"github.com/gofiber/fiber/v2"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
	"github.com/valyala/fasthttp"
)

func handleFormFileError(c *fiber.Ctx, err error) error {
	if errors.Is(err, fasthttp.ErrMissingFile) {
		return helpers.SendError(c, fiber.StatusBadRequest, "nu ai încărcat un fișier", err)
	}

	return fmt.Errorf("failed to get form file: %w", err)
}

func getWorkSupertypeQuery(c *fiber.Ctx, workType string) (string, error) {
	query, ok := gqlqueries.InsertWorkSupertype[workType]
	if !ok {
		return "", helpers.SendError(c, fiber.StatusBadRequest, "tipul lucrării selectat este invalid", nil)
	}

	return query, nil
}

func parseFormFile(c *fiber.Ctx, client *tika.Client) (string, error) {
	formFile, err := c.FormFile("file")
	if err != nil {
		return "", handleFormFileError(c, err)
	}

	file, err := formFile.Open()
	if err != nil {
		return "", fmt.Errorf("failed to open form file: %w", err)
	}

	m, err := client.Detect(c.Context(), file)
	if err != nil {
		return "", fmt.Errorf("tika failed to detect MIME-type: %w", err)
	}

	_, err = file.Seek(0, io.SeekStart)
	if err != nil {
		return "", fmt.Errorf("failed to seek file to beginning: %w", err)
	}

	var body string

	switch m {
	case mime.DOC, mime.DOCX, mime.RTF, mime.ODT:
		body, err = client.Parse(c.Context(), file)
		if err != nil {
			return "", fmt.Errorf("tika failed to parse: %w", err)
		}
	case mime.TXT:
		s := &strings.Builder{}
		if _, err = io.Copy(s, file); err != nil {
			return "", fmt.Errorf("failed to copy form file: %w", err)
		}

		body = s.String()
	default:
		return "", helpers.SendError(c, http.StatusBadRequest, "tipul fișierului încărcat nu este suportat", nil)
	}

	return body, nil
}

//nolint:lll
func insertWork(c *fiber.Ctx, body string, supertypeQuery string, input helpers.WorkFormInput, client *graphql.Client) (*gqlqueries.InsertWorkOutput, error) {
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
			"status":             "pending",
			"content":            body,
			"requestedTeacherID": nil,
		},
		Promote: true,
	}

	if input.RequestedTeacherID != 0 {
		workOpts.Vars["requestedTeacherID"] = input.RequestedTeacherID
	}

	if claims.Role == "teacher" {
		workOpts.Vars["status"] = "approved"
	} else if info, err := fetchUserInfo(c, client); info != nil && info.Role == "teacher" {
		workOpts.Vars["status"] = "approved"
	} else if info == nil {
		return nil, err
	}

	if err := helpers.GraphQLRequest(client, gqlqueries.InsertWork, workOpts); err != nil {
		return nil, helpers.HandleGraphQLError(c, err)
	}

	//nolint:exhaustivestruct
	supertypeOpts := helpers.GraphQLRequestOptions{
		Context: c.Context(),
		Vars: map[string]interface{}{
			"workID":    work.Query.ID,
			"subjectID": input.SubjectID,
		},
		Promote: true,
	}
	if err := helpers.GraphQLRequest(client, supertypeQuery, supertypeOpts); err != nil {
		return nil, helpers.HandleGraphQLError(c, err)
	}

	return &work, nil
}

func Upload(tikaClient *tika.Client, graphQLClient *graphql.Client) fiber.Handler {
	return func(c *fiber.Ctx) (err error) {
		var workInput helpers.WorkFormInput

		// Va trece de eroarea asta chiar daca nu sunt prezente toate campurile formularului
		if err := c.BodyParser(&workInput); err != nil {
			return helpers.SendError(c, http.StatusBadRequest, "formularul de încărcare este invalid", err)
		}

		supertypeQuery, err := getWorkSupertypeQuery(c, workInput.Type)
		if supertypeQuery == "" {
			return err
		}

		body, err := parseFormFile(c, tikaClient)
		if body == "" {
			return err
		}

		work, err := insertWork(c, body, supertypeQuery, workInput, graphQLClient)
		if work == nil {
			return err
		}

		return c.Status(http.StatusCreated).JSON(work.Query)
	}
}
