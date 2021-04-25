package logger_test

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"testing"

	"github.com/FiveIT/eseuri/internal/server/helpers"
	"github.com/FiveIT/eseuri/internal/server/middleware/logger"
	"github.com/FiveIT/eseuri/internal/testhelper"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/utils"
	"github.com/machinebox/graphql"
	"github.com/rs/zerolog"
)

func TestLoggerOutput(t *testing.T) {
	t.Parallel()

	out := &bytes.Buffer{}

	middleware := func(c *fiber.Ctx) error {
		logger, ok := c.Locals("logger").(zerolog.Logger)
		if ok {
			logger.Log().Msg("success")
		}

		return c.Next()
	}

	app := testhelper.App(t, logger.Middleware(nil, out), middleware)
	req := testhelper.Request(t, fiber.MethodGet, "/", nil)
	req.Header.Set(fiber.HeaderUserAgent, "test")
	req.Header.Set(fiber.HeaderXForwardedFor, "192.168.1.5")

	res := testhelper.DoTestRequest(t, app, req)
	res.Body.Close()

	testhelper.AssertSuccess(t, res)

	type logOutput struct {
		UserAgent string
		IPs       []string
		Message   string
	}

	var (
		output   logOutput
		expected = logOutput{
			UserAgent: "test",
			IPs:       []string{"192.168.1.5"},
			Message:   "success",
		}
	)

	testhelper.DecodeJSON(t, out, &output)

	utils.AssertEqual(t, expected, output)
}

// Subtests can't run in parallel because they write
// to the same buffer, which would cause a data race.
//nolint:tparallel
func TestGraphQLLogger(t *testing.T) {
	t.Parallel()

	globalLevel := zerolog.GlobalLevel()
	defer zerolog.SetGlobalLevel(globalLevel)

	zerolog.SetGlobalLevel(zerolog.DebugLevel)

	client := graphql.NewClient("")
	buf := &bytes.Buffer{}
	app := testhelper.App(t, logger.Middleware(client, buf))

	type testCase struct {
		Name           string
		ExpectedOutput string
		SetLogFn       func(*http.Request)
	}

	tests := []testCase{
		{
			Name:           "No logger",
			ExpectedOutput: "",
			SetLogFn:       func(*http.Request) {},
		},
		{
			Name:           "Custom logger",
			ExpectedOutput: "graphql",
			SetLogFn:       helpers.ShowGraphQLClientLogs,
		},
	}

	//nolint:paralleltest,scopelint
	for _, test := range tests {
		t.Run(test.Name, func(t *testing.T) {
			client.Log = nil
			buf.Reset()

			req := testhelper.Request(t, fiber.MethodGet, "/", nil)
			test.SetLogFn(req)
			res := testhelper.DoTestRequest(t, app, req)
			res.Body.Close()

			testhelper.AssertSuccess(t, res)

			if client.Log == nil {
				t.Fatal("GraphQL client logger was not set")
			}

			client.Log("")

			var output struct {
				Where string
			}

			err := json.NewDecoder(buf).Decode(&output)
			if err != nil && !errors.Is(err, io.EOF) {
				t.Fatalf("Failed to unmarshal JSON: %v", err)
			}
			utils.AssertEqual(t, test.ExpectedOutput, output.Where)
		})
	}
}
