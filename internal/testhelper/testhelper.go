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

	"github.com/FiveIT/template/internal/meta"
	"github.com/FiveIT/template/internal/server/config"
	"github.com/gofiber/fiber/v2"
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

func App(tb testing.TB, successResponse string, middlewares ...interface{}) *fiber.App {
	tb.Helper()

	app := fiber.New(config.Config())

	app.Use(middlewares...)

	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString(successResponse)
	})

	return app
}

func JWT(tb testing.TB) string {
	tb.Helper()

	token, err := meta.Auth0.AuthorizationToken(context.Background())
	if err != nil {
		tb.Fatalf("Failed to get JWT: %v", token)
	}

	// Sleep to prevent JWT error "Token used before issued"
	const seconds = 3

	time.Sleep(time.Second * seconds)

	return token
}

func Request(tb testing.TB, method string, body io.Reader) *http.Request {
	tb.Helper()

	return httptest.NewRequest(method, "https://eseuri.com", body)
}

// TODO: Helper functions for registering users and creating teachers
