//nolint:gochecknoglobals
package server_test

import (
	"context"
	"embed"
	"io/fs"
	"os"
	"strings"
	"testing"

	"github.com/FiveIT/eseuri/internal/meta"
	"github.com/FiveIT/eseuri/internal/meta/gqlqueries"
	"github.com/FiveIT/eseuri/internal/server"
	"github.com/FiveIT/eseuri/internal/server/helpers"
	"github.com/FiveIT/eseuri/internal/testhelper"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/utils"
	"github.com/machinebox/graphql"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

//go:embed testdata/*
var files embed.FS

var (
	token string
	gql   = graphql.NewClient(meta.HasuraEndpoint + "/v1/graphql")
)

func TestMain(m *testing.M) {
	zerolog.SetGlobalLevel(zerolog.InfoLevel)

	auth, err := meta.Auth0.AuthorizationToken(context.Background(), true)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to get Auth0 token")
	}

	token = auth

	code := m.Run()

	//nolint:exhaustivestruct
	if err = helpers.GraphQLRequest(gql, gqlqueries.Clear, helpers.GraphQLRequestOptions{
		Promote: true,
	}); err != nil {
		log.Err(err).Msg("failed to clear up the database")
	}

	os.Exit(code)
}

func file(tb testing.TB, name string) fs.File {
	tb.Helper()

	if !strings.Contains(name, ".") {
		name = "file." + name
	}

	f, err := files.Open("testdata/" + name)
	if err != nil {
		tb.Fatalf("Couldn't open test file %q: %v", name, err)
	}

	return f
}

func createTeacher(tb testing.TB) int {
	tb.Helper()

	var resp gqlqueries.InsertTeacherOutput

	//nolint:exhaustivestruct
	if err := helpers.GraphQLRequest(gql, gqlqueries.InsertTeacher, helpers.GraphQLRequestOptions{
		Output: &resp,
		Vars: map[string]interface{}{
			"email":   "teacher@example.com",
			"auth0ID": "auth0|0123456789",
		},
		Promote: true,
	}); err != nil {
		tb.Fatalf("failed to create new teacher: %v", err)
	}

	return resp.Query.ID
}

func TestFiles(t *testing.T) {
	t.Parallel()

	app := server.New()

	type testCase struct {
		Name               string
		ExpectedStatusCode int
	}

	tests := []testCase{
		{
			Name:               "PNG",
			ExpectedStatusCode: fiber.StatusBadRequest,
		},
		{Name: "DOC"},
		{Name: "DOCX"},
		{Name: "ODT"},
		{Name: "RTF"},
		{Name: "TXT"},
		{
			Name:               "",
			ExpectedStatusCode: fiber.StatusBadRequest,
		},
	}

	//nolint:paralleltest
	for _, test := range tests {
		var f fs.File

		name := test.Name
		if name == "" {
			name = "No"
		} else {
			f = file(t, strings.ToLower(name))
		}

		code := test.ExpectedStatusCode
		if code == 0 {
			code = fiber.StatusCreated
		}

		t.Run(name+" file", func(t *testing.T) {
			t.Parallel()

			res := testhelper.RequestMultipart(t, app, "/upload", token, map[string]interface{}{
				"file":    f,
				"type":    "essay",
				"subject": 1,
			})
			defer res.Body.Close()

			utils.AssertEqual(t, code, res.StatusCode)
		})
	}
}

func TestInvalidType(t *testing.T) {
	t.Parallel()

	app := server.New()

	res := testhelper.RequestMultipart(t, app, "/upload", token, map[string]interface{}{
		"file":    file(t, "txt"),
		"type":    "lol",
		"subject": 1,
	})
	defer res.Body.Close()

	utils.AssertEqual(t, fiber.StatusBadRequest, res.StatusCode)
}

func TestRequestedTeacher(t *testing.T) {
	t.Parallel()

	teacherID := createTeacher(t)

	app := server.New()

	res := testhelper.RequestMultipart(t, app, "/upload", token, map[string]interface{}{
		"file":             file(t, "teacher.docx"),
		"type":             "characterization",
		"subject":          1,
		"requestedTeacher": teacherID,
	})
	defer res.Body.Close()

	utils.AssertEqual(t, fiber.StatusCreated, res.StatusCode)
}
