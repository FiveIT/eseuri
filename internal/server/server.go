package server

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"

	"github.com/FiveIT/template/internal/meta"
	"github.com/FiveIT/template/internal/mime"
	"github.com/dgrijalva/jwt-go"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
	//"github.com/rs/zerolog/log"
)

type Eseu struct {
	Titlu         int    `form:"titlu"`
	TipLucrare    string `form:"tipul_lucrarii"`
	Caracter      int    `form:"caracter"`
	Creator       string
	CorectorCerut int `form:"corector_cerut"`
}

func sendError(c *fiber.Ctx, statusCode int, message string) error {
	return c.Status(statusCode).JSON(&fiber.Map{
		"error": message,
	})
}

func handleGraphQLError(c *fiber.Ctx, err error) error {
	if errVal := err.Error(); strings.Contains(errVal, "graphql: ") {
		if !strings.Contains(errVal, "server returned a non-200 status code") {

			return sendError(c, http.StatusBadRequest, "eroare la interogarea bazei de date: "+err.Error())
		}
	}

	return sendError(c, http.StatusInternalServerError, "a aparut o eroare la conectarea cu baza de date")
}

type customClaims struct {
	Role                     string
	AllowedRoles             []string
	UserID                   int
	HasCompletedRegistration bool
}

const (
	hasuraNamespace = "https://hasura.io/jwt/claims"
	eseuriNamespace = "https://eseuri.com"
)

type jwtClaim map[string]interface{}

func (j *jwtClaim) Valid() error {
	ref := *j

	log.Printf("%+v", ref)

	claims := jwt.StandardClaims{
		ExpiresAt: int64(ref["exp"].(float64)),
		IssuedAt:  int64(ref["iat"].(float64)),
		Issuer:    ref["iss"].(string),
		Subject:   ref["sub"].(string),
	}

	aud, ok := ref["aud"].([]interface{})
	if ok {
		claims.Audience = aud[0].(string)
	} else {
		claims.Audience = ref["aud"].(string)
	}

	return claims.Valid()
}

func (j *jwtClaim) getCustomClaims() *customClaims {
	ref := *j

	hasura := ref[hasuraNamespace].(map[string]interface{})
	eseuri := ref[eseuriNamespace].(map[string]interface{})

	//nolint:exhaustivestruct
	claims := &customClaims{}

	claims.Role = hasura["X-Hasura-Default-Role"].(string)

	roles := []string{}

	for _, r := range hasura["X-Hasura-Allowed-Roles"].([]interface{}) {
		roles = append(roles, r.(string))
	}

	claims.AllowedRoles = roles
	claims.UserID, _ = strconv.Atoi(hasura["X-Hasura-User-Id"].(string))
	claims.HasCompletedRegistration = eseuri["hasCompletedRegistration"].(bool)

	return claims
}

type jsonCert struct {
	Alg         string `json:"type"`
	Certificate string `json:"key"`
}

func New() *fiber.App {
	app := fiber.New(fiber.Config{
		ReadBufferSize: 8192,
	})
	graphqlClient := graphql.NewClient(meta.HasuraEndpoint + "/v1/graphql")
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
			return sendError(c, http.StatusBadRequest, "nu s-a putut citi formularul")
		}
		fisierraw, err := c.FormFile("document")
		if err != nil {
			return sendError(c, http.StatusBadRequest, "nu s-a putut obtine documentul")
		}
		fisierprocesat, err := fisierraw.Open()
		if err != nil {
			log.Println(err)

			return sendError(c, http.StatusBadRequest, "nu s-a putut deschide documentul")
		}
		m, err := client.Detect(c.Context(), fisierprocesat)
		if err != nil {
			log.Println(err)

			return sendError(c, http.StatusInternalServerError, "eroare internă")
		}
		_, err = fisierprocesat.Seek(0, io.SeekStart)
		if err != nil {
			log.Println(err)

			return sendError(c, http.StatusInternalServerError, "eroare internă")
		}

		var body string

		switch m {
		case mime.DOC, mime.DOCX, mime.RTF, mime.ODT:
			body, err = client.Parse(c.Context(), fisierprocesat)
			if err != nil {
				log.Println(err)

				return sendError(c, http.StatusInternalServerError, "eroare internă")
			}
		default:
			return sendError(c, http.StatusBadRequest, "fișierul trimis nu este de un tip valid")
		}
		// Verificam tokenul userului (Note: PENTRU FRONTEND, trimiteti fără "Bearer", doar tokenul în sine)
		infoLucrare.Creator = c.Get("Authorization")
		if infoLucrare.Creator == "" {
			log.Println(err)

			return sendError(c, http.StatusUnauthorized, "tokenul nu a fost primit")
		}

		// Se face request la Hasura de inserare cu detaliile din form
		// Certificatul se obține din Settings >> Signing Keys și este luat cel în folosire
		// Decodez JWT

		var jsonCertificatAuth0 jsonCert
		err = json.Unmarshal([]byte(meta.HasuraJWTSecret), &jsonCertificatAuth0)
		if err != nil || jsonCertificatAuth0.Alg != "RS512" {
			log.Println(err)

			return sendError(c, http.StatusInternalServerError, "certificatul Auth0 nu e valid")
		}
		rsaAuth0Key, err := jwt.ParseRSAPublicKeyFromPEM([]byte(jsonCertificatAuth0.Certificate))
		if err != nil {
			log.Println()

			return sendError(c, http.StatusInternalServerError, "nu s-a putut obține cheia publică")
		}

		token, err := jwt.ParseWithClaims(infoLucrare.Creator, &jwtClaim{}, func(token *jwt.Token) (interface{}, error) {
			// since we only use the one private key to sign the tokens,
			// we also only use its public counter part to verify
			return rsaAuth0Key, nil
		})
		if err != nil {
			log.Println(err)

			return sendError(c, http.StatusUnauthorized, "token invalid")
		}

		claims := token.Claims.(*jwtClaim)
		custom := claims.getCustomClaims()
		if !custom.HasCompletedRegistration {
			return sendError(c, http.StatusUnauthorized, "nu ai finalizat înregistrarea")
		}

		req := graphql.NewRequest(`
		mutation insertWork ($content: String!, $requestedTeacherID: Int) {
			insert_works_one (object: {content: $content, status: pending, teacher_id: $requestedTeacherID}){
				id
			}
		}
		`)

		req.Var("content", body)
		if infoLucrare.CorectorCerut != 0 {
			req.Var("requestedTeacherID", infoLucrare.CorectorCerut)
		} else {
			req.Var("requestedTeacherID", nil)
		}

		// Setez X-Hasura-user-id cu ce am decodat din JWT ca si user id
		req.Header.Add("X-Hasura-Role", custom.Role)
		req.Header.Add("X-Hasura-User-Id", strconv.Itoa(custom.UserID))
		req.Header.Add("X-Hasura-Admin-Secret", meta.HasuraAdminSecret)
		req.Header.Add("X-Hasura-Use-Backend-Only-Permissions", "true")

		var resp struct {
			Query struct {
				ID int `json:"id"`
			} `json:"insert_works_one"`
		}

		err = graphqlClient.Run(c.Context(), req, &resp)
		if err != nil {
			return handleGraphQLError(c, err)
		}

		log.Println("Work inserted successfully, id", resp.Query.ID)

		idLucrare := resp.Query.ID

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
			return sendError(c, http.StatusUnauthorized, "tipul lucrării nu este valid")
		}

		req.Var("workID", idLucrare)
		if infoLucrare.TipLucrare == "essay" {
			req.Var("titleID", infoLucrare.Titlu)
		} else if infoLucrare.TipLucrare == "characterization" {
			req.Var("characterID", infoLucrare.Caracter)
		}

		req.Header.Add("X-Hasura-Admin-Secret", meta.HasuraAdminSecret)
		req.Header.Add("X-Hasura-Use-Backend-Only-Permissions", "true")

		err = graphqlClient.Run(c.Context(), req, &resp)
		if err != nil {
			return handleGraphQLError(c, err)
		}

		return c.SendStatus(http.StatusOK)
	})

	// 404 Not found handler
	routes.Use(func(c *fiber.Ctx) error {
		return c.Status(http.StatusNotFound).SendString("nu am gasit acest loc")
	})

	return app
}
