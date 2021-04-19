package server

import (
	"log"
	"net/http"

	"github.com/FiveIT/template/internal/meta"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
)

type Eseu struct {
	Titlu         int    `form:"titlu"`
	TipLucrare    string `form:"tipul_lucrarii"`
	Caracter      int    `form:"caracter"`
	Creator       string
	CorectorCerut string `form:"corector_cerut"`
}

type Data struct {
	Query struct {
		ID int `json:"id"`
	} `json:"insert_works_one"`
	Errors []struct {
		Extensions struct {
			Code string `json:"code"`
		} `json:"extensions"`
	} `json:"errors"`
}

func New() *fiber.App {
	app := fiber.New()
	graphqlClient := graphql.NewClient(meta.HasuraEndpoint + "/v1/graphql")
	/*
		graphqlClient.Log = func(s string) {
			log.Println(s)
		}
	*/
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
		infoLucrare := new(Eseu)
		// Va trece de eroarea asta chiar daca nu sunt oferite toate variabilele
		// structurii Eseu
		if err := c.BodyParser(infoLucrare); err != nil {
			return c.Status(http.StatusBadRequest).JSON(&fiber.Map{
				"success": false,
				"error":   "Nu s-a putut să se preia datele formularului.",
			})
		}
		fisierraw, err := c.FormFile("document")
		if err != nil {
			return c.Status(http.StatusBadRequest).JSON(&fiber.Map{
				"success": false,
				"error":   "Nu s-a putut obtine documentul.",
			})
		}
		fisierprocesat, err := fisierraw.Open()
		if err != nil {
			return c.Status(http.StatusBadRequest).JSON(&fiber.Map{
				"success": false,
				"error":   "Nu s-a putut deschide documentul.",
			})
		}
		body, err := client.Parse(c.Context(), fisierprocesat)
		if err != nil {
			return c.Status(http.StatusUnauthorized).JSON(&fiber.Map{
				"success": false,
				"error":   "Nu s-a putut procesa documentul (este un format valid?).",
			})
		}
		// Verificam tokenul userului
		infoLucrare.Creator = c.Get("Authorization")
		if infoLucrare.Creator == "" {
			return c.Status(http.StatusUnauthorized).JSON(&fiber.Map{
				"success": false,
				"error":   "Tokenul de autentificare al utilizatorului nu a fost trimis.",
			})
		}

		// Se face request la Hasura de inserare cu detaliile din form

		req := graphql.NewRequest(`
		mutation insertWork ($userID: Int!, $content: String!, $requestedTeacherID: Int) {
			insert_works_one (object: {user_id:$userID, content: $content, status: pending, teacher_id: $requestedTeacherID}){
				id
			}
		}
		`)

		// Decodez JWT

		// Setez X-Hasura-user-id cu ce am decodat din JWT ca si user id

		req.Var("content", body)
		if infoLucrare.CorectorCerut != "" {
			req.Var("requestedTeacherID", infoLucrare.CorectorCerut)
		} else {
			req.Var("requestedTeacherID", nil)
		}

		req.Var("userID", 1)
		req.Header.Add("X-Hasura-Admin-Secret", meta.HasuraAdminSecret)
		req.Header.Add("X-Hasura-Use-Backend-Only-Permissions", "true")

		var resp Data
		// Fixează erori la requesturile de GraphQL
		if err := graphqlClient.Run(c.Context(), req, &resp); err != nil {
			log.Println(err)
			log.Println(resp)
			// log.Println(resp.Query.ID)

			return c.Status(http.StatusInternalServerError).JSON(&fiber.Map{
				"success": false,
				"error":   "Eroare de conectare la baza de date.",
			})
		}
		var idLucrare int

		idLucrare = resp.Query.ID

		switch infoLucrare.TipLucrare {
		case "essay":
			req = graphql.NewRequest(`
			mutation insertEssay($workID: Int!, $titleID: Int!) {
  				insert_essays_one(object: {work_id: $workID, title_id: $titleID}) {
    				__typename
  				}
			}`)

		case "characterization":
			req = graphql.NewRequest(`
			mutation insertCharacterization($workID: Int!, $characterID: Int!) {
  				insert_characterizations_one(object: {work_id: $workID, character_id: $characterID}) {
    				__typename
  				}
			}`)

		default:
			return c.Status(http.StatusBadRequest).JSON(&fiber.Map{
				"success": false,
				"error":   "Tipul lucrarii nu este valid.",
			})
		}

		req.Var("workID", idLucrare)
		if infoLucrare.TipLucrare == "essay" {
			req.Var("titleID", infoLucrare.Titlu)
		} else if infoLucrare.TipLucrare == "characterization" {
			req.Var("characterID", infoLucrare.Caracter)
		}

		req.Header.Add("X-Hasura-Admin-Secret", meta.HasuraAdminSecret)
		req.Header.Add("X-Hasura-Use-Backend-Only-Permissions", "true")

		if err := graphqlClient.Run(c.Context(), req, &resp); err != nil {
			log.Println(err)
			log.Println(resp)

			return c.Status(http.StatusInternalServerError).JSON(&fiber.Map{
				"success": false,
				"error":   "Eroare de conectare la baza de date.",
			})
		}

		return c.SendStatus(http.StatusOK)
	})

	// 404 Not found handler
	routes.Use(func(c *fiber.Ctx) error {
		return c.Status(http.StatusNotFound).SendString("nu am gasit acest loc")
	})

	return app
}
