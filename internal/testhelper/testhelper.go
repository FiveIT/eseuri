package testhelper

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/FiveIT/eseuri/internal/meta"
	"github.com/FiveIT/eseuri/internal/server/config"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/utils"
)

func DecodeJSON(tb testing.TB, r io.Reader, v interface{}) {
	tb.Helper()

	if err := json.NewDecoder(r).Decode(v); err != nil {
		tb.Fatalf("Failed to decode JSON: %v", err)
	}
}

func ReadString(tb testing.TB, r io.Reader) string {
	tb.Helper()

	s := &strings.Builder{}

	_, err := io.Copy(s, r)
	if err != nil {
		tb.Fatalf("Failed to copy reader into string: %v", err)
	}

	return s.String()
}

func DoTestRequest(tb testing.TB, app *fiber.App, req *http.Request) *http.Response {
	tb.Helper()

	res, err := app.Test(req)
	if err != nil {
		tb.Fatalf("Failed to do test request: %v", err)
	}

	return res
}

func App(tb testing.TB, middlewares ...interface{}) *fiber.App {
	tb.Helper()

	app := fiber.New(config.Config())

	app.Use(middlewares...)

	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendStatus(fiber.StatusNoContent)
	})

	return app
}

func JWT(tb testing.TB, registerUser ...bool) string {
	tb.Helper()

	token, err := meta.Auth0.AuthorizationToken(context.Background(), registerUser...)
	if err != nil {
		tb.Fatalf("Failed to get JWT: %v", token)
	}

	// Sleep to prevent JWT error "Token used before issued"
	const seconds = 3

	time.Sleep(time.Second * seconds)

	return token
}

func Request(tb testing.TB, method string, path string, body io.Reader, authorization ...string) *http.Request {
	tb.Helper()

	req := httptest.NewRequest(method, "https://eseuri.com"+path, body)

	for _, auth := range authorization {
		if auth != "" {
			req.Header.Set("Authorization", auth)
		}

		break
	}

	return req
}

func AssertSuccess(tb testing.TB, res *http.Response) {
	tb.Helper()

	utils.AssertEqual(tb, fiber.StatusNoContent, res.StatusCode)
}

// TODO: Helper functions for creating teachers
