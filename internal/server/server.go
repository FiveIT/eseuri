package server

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/FiveIT/template/internal/meta"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/google/go-tika/tika"
)

type Eseu struct {
	Titlu         string `form:"titlu"`
	TipLucrare    string `form:"tipul_lucrarii"`
	Caracter      string `form:"caracter"`
	Creator       string `form:"auth_token"`
	CorectorCerut string `form:"corector_cerut"`
}

const succes_code = 200

func New() *fiber.App {
	app := fiber.New()
	post_client := &http.Client{}
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

	routes.Post("/upload", func(context *fiber.Ctx) error {
		infoLucrare := new(Eseu)
		if err := context.BodyParser(infoLucrare); err != nil {
			return fmt.Errorf("error: %w", err)
		}
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

		// log.Println(infoLucrare.Caracter)

		// Se face request la Hasura de inserare cu detaliile din form

		reqBody, err := json.Marshal(map[string]string{})

		if err != nil {
			return fmt.Errorf("error: %w", err)
		}

		req, err := http.NewRequestWithContext(context.Context(), "POST", meta.HasuraURL, bytes.NewBuffer(reqBody))

		if err != nil {
			return fmt.Errorf("error: %w", err)
		}

		req.Header.Add("Authorization", "Bearer "+infoLucrare.Creator)
		req.Header.Add("content-type", "application/json")

		resp, err := post_client.Do(req)

		if err != nil {
			return fmt.Errorf("error: %w", err)
		}

		if resp.StatusCode == succes_code {
			log.Println("Success!")
		}

		return context.SendString(body)
	})

	// 404 Not found handler
	routes.Use(func(c *fiber.Ctx) error {
		return c.Status(http.StatusNotFound).SendString("nu am gasit acest loc")
	})

	return app
}
