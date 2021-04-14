package server

import (
	"fmt"
	"log"
	"net/http"

	"github.com/FiveIT/template/internal/meta"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
)

type Eseu struct {
	Titlu         string `form:"titlu"`
	TipLucrare    string `form:"tipul_lucrarii"`
	Caracter      string `form:"caracter"`
	Creator       string `form:"auth_token"`
	CorectorCerut string `form:"corector_cerut"`
}
type response struct {
	Name  string
	Items struct {
		Records []struct {
			Title string
		}
	}
}

func New() *fiber.App {
	app := fiber.New()
	graphqlClient := graphql.NewClient(meta.HasuraURL)
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

	routes.Post("/upload", func(c *fiber.Ctx) (err error) {
		defer func() {
			if err != nil {
				err = fmt.Errorf("upload error: %w", err)
			}
		}()
		infoLucrare := new(Eseu)
		if err := c.BodyParser(infoLucrare); err != nil {
			return fmt.Errorf("eroare de upload: %w", err)
		}
		fisierraw, err := c.FormFile("document")
		fisierprocesat, err := fisierraw.Open()
		body, err := client.Parse(c.Context(), fisierprocesat)
		log.Println(infoLucrare.Caracter)

		// Se face request la Hasura de inserare cu detaliile din form
		authorizationtoken := fmt.Sprintf("Bearer %s", infoLucrare.Creator)

		req := graphql.NewRequest(`
		mutation($content: String!, $userID: Int!) {
  			insert_works_one(object: {user_id: $userID, content: $content, status: pending) {
    			work_id
  				}
		}
`)
		req.Var("content", body)
		req.Var("userID", infoLucrare.Creator)
		req.Header.Add("Authorization", authorizationtoken)
		req.Header.Add("content-type", "application/json")
		// req.Header.Add("X-Hasura-Admin-Secret", meta.HasuraKey)
		// req.Header.Add("X-Hasura-Use-Backend-Only-Permissions", "true")
		var resp response
		if err := graphqlClient.Run(c.Context(), req, &resp); err != nil {
			return fmt.Errorf("error: %w", err)
		}

		log.Println(resp)

		return c.SendString(body)
	})

	// 404 Not found handler
	routes.Use(func(c *fiber.Ctx) error {
		return c.Status(http.StatusNotFound).SendString("nu am gasit acest loc")
	})

	return app
}
