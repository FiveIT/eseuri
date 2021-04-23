package server

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"

	"github.com/FiveIT/template/internal/meta"
	"github.com/FiveIT/template/internal/meta/gqlqueries"
	"github.com/FiveIT/template/internal/mime"
	"github.com/FiveIT/template/internal/server/helpers"
	"github.com/dgrijalva/jwt-go"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
	//"github.com/rs/zerolog/log"
)

type customClaims struct {
	Role                     string
	AllowedRoles             []string
	UserID                   int
	HasCompletedRegistration bool
}

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

	hasura := ref[helpers.HasuraNamespace].(map[string]interface{})
	eseuri := ref[helpers.EseuriNamespace].(map[string]interface{})

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

	//nolint:exhaustivestruct
	routes.Post("/upload", func(c *fiber.Ctx) (err error) {
		workInput := &helpers.WorkFormInput{}

		// Va trece de eroarea asta chiar daca nu sunt prezente toate campurile formularului
		if err := c.BodyParser(workInput); err != nil {
			return helpers.SendError(c, http.StatusBadRequest, "couldn't parse form", err)
		}

		file, err := workInput.File.Open()
		if err != nil {
			return helpers.SendError(c, http.StatusBadRequest, "couldn't open form content file", err)
		}

		m, err := client.Detect(c.Context(), file)
		if err != nil {
			return helpers.SendError(c, http.StatusInternalServerError, "internal error", err)
		}

		_, err = file.Seek(0, io.SeekStart)
		if err != nil {
			return helpers.SendError(c, http.StatusInternalServerError, "internal error", err)
		}

		var body string

		switch m {
		case mime.DOC, mime.DOCX, mime.RTF, mime.ODT:
			body, err = client.Parse(c.Context(), file)
			if err != nil {
				err = fmt.Errorf("tika failed to parse: %w", err)

				return helpers.SendError(c, http.StatusInternalServerError, "internal error", err)
			}
		case mime.TXT:
			s := &strings.Builder{}
			_, err = io.Copy(s, file)
			if err != nil {
				err = fmt.Errorf("failed to copy form file: %w", err)

				return helpers.SendError(c, http.StatusInternalServerError, "internal error", err)
			}
			body = s.String()
		default:
			return helpers.SendError(c, http.StatusBadRequest, "invalid form content file type", nil)
		}

		authorization := c.Get("Authorization", "")
		if authorization == "" {
			return helpers.SendError(c, http.StatusUnauthorized, "authorization token not sent", nil)
		}

		// Se face request la Hasura de inserare cu detaliile din form
		// Certificatul se obține din Settings >> Signing Keys și este luat cel în folosire
		// Decodez JWT

		var auth0Cert jsonCert
		err = json.Unmarshal([]byte(meta.HasuraJWTSecret), &auth0Cert)
		if err != nil || auth0Cert.Alg != "RS512" {
			err = fmt.Errorf("invalid Auth0 certificate: %w", err)

			return helpers.SendError(c, http.StatusInternalServerError, "internal error", err)
		}
		rsaAuth0Key, err := jwt.ParseRSAPublicKeyFromPEM([]byte(auth0Cert.Certificate))
		if err != nil {
			err = fmt.Errorf("couldn't retrieve Auth0 public key: %w", err)

			return helpers.SendError(c, http.StatusInternalServerError, "internal error", err)
		}

		token, err := jwt.ParseWithClaims(authorization, &jwtClaim{}, func(token *jwt.Token) (interface{}, error) {
			return rsaAuth0Key, nil
		})
		if err != nil {
			return helpers.SendError(c, http.StatusUnauthorized, "invalid token", err)
		}

		claims := token.Claims.(*jwtClaim)
		custom := claims.getCustomClaims()
		if !custom.HasCompletedRegistration {
			return helpers.SendError(c, http.StatusUnauthorized, "user is not registered", nil)
		}

		showGQLLogs := helpers.ShouldShowGraphQLClientLogs(c)

		var work gqlqueries.Work
		workOpts := helpers.GraphQLRequestOptions{
			Output:  &work,
			Context: c.Context(),
			Headers: map[string]string{
				"X-Hasura-Role":    custom.Role,
				"X-Hasura-User-Id": strconv.Itoa(custom.UserID),
			},
			Vars: map[string]interface{}{
				"content":            body,
				"requestedTeacherID": nil,
			},
			Promote: true,
			Log:     showGQLLogs,
		}
		if workInput.RequestedTeacherID != 0 {
			workOpts.Vars["requestedTeacherID"] = workInput.RequestedTeacherID
		}

		if err = helpers.GraphQLRequest(graphqlClient, gqlqueries.InsertWork, workOpts); err != nil {
			return helpers.HandleGraphQLError(c, err)
		}

		log.Println("Work inserted successfully, id", work.Query.ID)

		query, ok := gqlqueries.InsertWorkSupertype[workInput.Type]
		if !ok {
			return helpers.SendError(c, http.StatusBadRequest, fmt.Sprintf("invalid work type %q", workInput.Type), nil)
		}

		supertypeOpts := helpers.GraphQLRequestOptions{
			Context: c.Context(),
			Vars: map[string]interface{}{
				"workID":    work.Query.ID,
				"subjectID": workInput.SubjectID,
			},
			Promote: true,
			Log:     showGQLLogs,
		}
		if err = helpers.GraphQLRequest(graphqlClient, query, supertypeOpts); err != nil {
			return helpers.HandleGraphQLError(c, err)
		}

		return c.SendStatus(http.StatusOK)
	})

	// 404 Not found handler
	routes.Use(func(c *fiber.Ctx) error {
		return c.Status(http.StatusNotFound).SendString("nu am gasit acest loc")
	})

	return app
}
