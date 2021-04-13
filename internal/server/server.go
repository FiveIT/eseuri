package server

import (
	"fmt"
	"net/http"

	"github.com/FiveIT/template/internal/meta"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/google/go-tika/tika"
)

func New() *fiber.App {
	app := fiber.New()
	client := tika.NewClient(nil, meta.TikaURL)

	var routes fiber.Router = app
	if meta.IsNetlify {
		routes = app.Group(meta.FunctionsBasePath)
	}

	//nolint:exhaustivestruct
	routes.Use(cors.New(cors.Config{
		AllowOrigins: meta.URL(),
	}))

	// Routes go here
	routes.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("sarmale cu ghimbir")
	})

	routes.Post("/upload-file", func(context *fiber.Ctx) error {
		fisierraw, err := context.FormFile("document")
		if err != nil {
			return fmt.Errorf("error: %w", err)
		}
		fisierprocesat, err := fisierraw.Open()
		if err != nil {
			return fmt.Errorf("error: %w", err)
		}
		body, err := client.Parse(context.Context(), fisierprocesat)
		if err != nil {
			return fmt.Errorf("error: %w", err)
		}

		return context.SendString(body)
	})

	// 404 Not found handler
	routes.Use(func(c *fiber.Ctx) error {
		return c.Status(http.StatusNotFound).SendString("nu am gasit acest loc")
	})

	return app
}