package server

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/FiveIT/template/internal/meta"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
	"github.com/pascaldekloe/jwt"
)

type Eseu struct {
	Titlu         int    `form:"titlu"`
	TipLucrare    string `form:"tipul_lucrarii"`
	Caracter      int    `form:"caracter"`
	Creator       string
	CorectorCerut string `form:"corector_cerut"`
}

func SendError(c *fiber.Ctx, statusCode int, err error) error {
	return c.Status(statusCode).JSON(&fiber.Map{
		"error": err.Error(),
	})
}

func handleGraphQLError(c *fiber.Ctx, err error) error {
	if errVal := err.Error(); strings.Contains(errVal, "graphql: ") {
		if !strings.Contains(errVal, "server returned a non-200 status code") {
			return SendError(c, http.StatusBadRequest, err)
		}
	}

	return SendError(c, http.StatusInternalServerError, err)
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
			//nolint:stylecheck
			return SendError(c, http.StatusBadRequest, fmt.Errorf("Nu s-a putut citi formularul: %w", err))
		}
		fisierraw, err := c.FormFile("document")
		if err != nil {
			//nolint:stylecheck
			return SendError(c, http.StatusBadRequest, fmt.Errorf("Nu s-a putut obtine documentul: %w", err))
		}
		fisierprocesat, err := fisierraw.Open()
		if err != nil {
			//nolint:stylecheck
			return SendError(c, http.StatusBadRequest, fmt.Errorf("Nu s-a putut deschide documentul: %w", err))
		}
		// mime, err := client.Detect()
		// fisierprocesat.Seek(0, io.SeekStart)
		body, err := client.Parse(c.Context(), fisierprocesat)
		if err != nil {
			//nolint:stylecheck
			return SendError(c, http.StatusInternalServerError, fmt.Errorf("Eroare interna: %w", err))
		}
		// Verificam tokenul userului (Note: PENTRU FRONTEND, trimiteti fără "Bearer", doar tokenul în sine)
		infoLucrare.Creator = c.Get("Authorization")
		if infoLucrare.Creator == "" {
			//nolint
			return SendError(c, http.StatusUnauthorized, fmt.Errorf("Tokenul nu a fost primit."))
		}

		// Se face request la Hasura de inserare cu detaliile din form
		// FĂRĂ SPAȚII LA CERTIFICAT (LA STÂNGA)
		// Certificatul se obține din Settings >> Signing Keys și este luat cel în folosire
		// Decodez JWT

		pubPEMData := []byte(`
-----BEGIN CERTIFICATE-----
MIIDFTCCAf2gAwIBAgIJTto6VzP80+XtMA0GCSqGSIb3DQEBCwUAMCgxJjAkBgNV
BAMTHWVzZXVyaS1tYXRlaS1kZXYuZXUuYXV0aDAuY29tMB4XDTIxMDQxODE0NDAz
OVoXDTM0MTIyNjE0NDAzOVowKDEmMCQGA1UEAxMdZXNldXJpLW1hdGVpLWRldi5l
dS5hdXRoMC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDInz6F
1ujdyXEtriec3mQG+xfhB/Y/YAC3Uy4dYBTkRkKyG5BV4LFk7BNm/vsb3g3XIHGn
DIEzRk6sCBalhwdr5G6JHsI0/NeJpXuJl0QxtPSzRAGWvDLc8wRNc1HQRXgbw1V0
sKTb1R5OXs/3gUosDQP2QkzyY0iaX1Vf2yI5pdeWdCtJyNjsAef3/L/BVxGtgm6x
F/joFvKPLOuvNU9t2NT29Ymbh0zrBQLyxFluG0xr7pFcEL7WCfprED1Hd1x8c+Ih
PgqryLUpLFG1Nv9jSkA3G+h/7a53Yabus3uBn5RNh6gXqfdMW/KuYN1nAyn16A7Q
9lYyVc+30EFqWjL5AgMBAAGjQjBAMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYE
FNvV6H2apF4OW/cbWbdwj5585plbMA4GA1UdDwEB/wQEAwIChDANBgkqhkiG9w0B
AQsFAAOCAQEAl9aDXEL8mlPPCiLC5D2QyMDEhv/8AebV62I6DafdRUPW15BxtSz9
J6tpdvlhduLRAT3xg0BscPw+ZP+wmi08O8b2pnMTiK30/jzGKOAarOQh8e9iTIXP
0nhFBYPip95lVTvZSLffEZRh2nv5ifnQoLnpSNO2E5vhSGlM8daCD5tO0QL3lILx
1iEjwuTwFcE6uiKe7em/BvmGV+A21PzhIyUPORuZmxbuSf/8xABhheqwA0cZ1tjM
2aOaaf1ybDBjW3rKtdmjGZ+JCFpUIKNIGX5LOVTI8btFOa/GGSG9uGDFMmK5gO0E
hok0CSJqAzVetz2/4g1zp5LWq9t+Mgp7lQ==
-----END CERTIFICATE-----`)

		block, _ := pem.Decode(pubPEMData)
		var cert *x509.Certificate
		cert, err = x509.ParseCertificate(block.Bytes)
		if err != nil {
			//nolint
			return SendError(c, http.StatusInternalServerError, fmt.Errorf("Eroare procesare certificat Auth0: %w", err))
		}
		publicKey := cert.PublicKey.(*rsa.PublicKey)
		claims, err := jwt.RSACheck([]byte(infoLucrare.Creator), publicKey)
		if err != nil {
			log.Println(err)
			//nolint
			return SendError(c, http.StatusUnauthorized, fmt.Errorf("Tokenul nu este valid."))
		}

		if !claims.Valid(time.Now()) {
			//nolint
			return SendError(c, http.StatusUnauthorized, fmt.Errorf("Tokenul a expirat."))
		}

		if !(claims.Issuer == meta.Auht0Enpoint) {
			//nolint
			return SendError(c, http.StatusUnauthorized, fmt.Errorf("Tokenul nu este destinat domeniului eseuri.com."))
		}

		// Setez X-Hasura-user-id cu ce am decodat din JWT ca si user id

		log.Println(string(claims.Raw))

		req := graphql.NewRequest(`
		mutation insertWork ($userID: Int!, $content: String!, $requestedTeacherID: Int) {
			insert_works_one (object: {user_id:$userID, content: $content, status: pending, teacher_id: $requestedTeacherID}){
				id
			}
		}
		`)

		req.Var("content", body)
		if infoLucrare.CorectorCerut != "" {
			req.Var("requestedTeacherID", infoLucrare.CorectorCerut)
		} else {
			req.Var("requestedTeacherID", nil)
		}

		req.Var("userID", 1)
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
			//nolint
			return SendError(c, http.StatusUnauthorized, fmt.Errorf("Tipul lucrării nu este valid."))
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
