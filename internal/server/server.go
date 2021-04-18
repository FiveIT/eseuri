package server

import (
	"fmt"
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
	id int
}

func New() *fiber.App {
	app := fiber.New()
	graphqlClient := graphql.NewClient(meta.HasuraEndpoint)
	client := tika.NewClient(nil, meta.TikaEndpoint)

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
		// log.Println(infoLucrare.Caracter)
		if infoLucrare.Creator == "" {
			return c.Status(http.StatusBadRequest).JSON(&fiber.Map{
				"success": false,
				"error":   "Tokenul de autentificare al utilizatorului nu a fost trimis",
			})
		}
		// Se face request la Hasura de inserare cu detaliile din form
		authorizationtoken := fmt.Sprintf("Bearer %s", infoLucrare.Creator)

		req := graphql.NewRequest(`
		mutation insertWork ($content: String!, $requestedTeacherID: Int) {
			insert_works_one (object: {content: $content, status: pending, teacher_id: $requestedTeacherID}){
				id
			}
		}
		`)

		req.Var("content", body)
		req.Var("requestedTeacherID", infoLucrare.CorectorCerut)
		req.Header.Add("Authorization", authorizationtoken)
		req.Header.Add("X-Hasura-Admin-Secret", meta.HasuraAdminSecret)
		req.Header.Add("X-Hasura-Use-Backend-Only-Permissions", "true")

		var resp response
		if err := graphqlClient.Run(c.Context(), req, &resp); err != nil {
			return fmt.Errorf("eroare la query: %w", err)
		}

		var idLucrare int
		resp.id = idLucrare

		switch infoLucrare.TipLucrare {
		case "essay":
			{
				req := graphql.NewRequest(`
			mutation insertEssay($workID: Int!, $titleID: Int!) {
  				insert_essays_one(object: {work_id: $workID, title_id: $titleID}) {
    				__typename
  				}
			}`)

				req.Var("workID", idLucrare)
				req.Var("titleID", infoLucrare.Titlu)
				req.Header.Add("Authorization", authorizationtoken)
				req.Header.Add("X-Hasura-Admin-Secret", meta.HasuraAdminSecret)
				req.Header.Add("X-Hasura-Use-Backend-Only-Permissions", "true")

				if err := graphqlClient.Run(c.Context(), req, &resp); err != nil {
					return fmt.Errorf("eroare la query: %w", err)
				}
			}
		case "characterization":
			{
				req := graphql.NewRequest(`
			mutation insertCharacterization($workID: Int!, $characterID: Int!) {
  				insert_characterizations_one(object: {work_id: $workID, character_id: $characterID}) {
    				__typename
  				}
			}`)

				req.Var("workID", idLucrare)
				req.Var("characterID", infoLucrare.Caracter)
				req.Header.Add("Authorization", authorizationtoken)
				req.Header.Add("X-Hasura-Admin-Secret", meta.HasuraAdminSecret)
				req.Header.Add("X-Hasura-Use-Backend-Only-Permissions", "true")

				if err := graphqlClient.Run(c.Context(), req, &resp); err != nil {
					return fmt.Errorf("eroare la query: %w", err)
				}
			}
		default:
			{
				return c.Status(http.StatusBadRequest).JSON(&fiber.Map{
					"success": false,
					"error":   "Tipul lucrarii nu este valid.",
				})
			}
		}

		return c.SendStatus(http.StatusAccepted)
	})

	// 404 Not found handler
	routes.Use(func(c *fiber.Ctx) error {
		return c.Status(http.StatusNotFound).SendString("nu am gasit acest loc")
	})

	return app
}
