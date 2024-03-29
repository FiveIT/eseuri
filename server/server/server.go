package server

import (
	"github.com/FiveIT/eseuri/server/meta"
	"github.com/FiveIT/eseuri/server/server/config"
	"github.com/FiveIT/eseuri/server/server/middleware/auth"
	"github.com/FiveIT/eseuri/server/server/middleware/logger"
	"github.com/FiveIT/eseuri/server/server/routes"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
)

func New() *fiber.App {
	graphQLClient := graphql.NewClient(meta.HasuraEndpoint + "/v1/graphql")
	tikaClient := tika.NewClient(nil, meta.TikaEndpoint)

	app := fiber.New(config.Config())

	var r fiber.Router = app
	if meta.IsNetlify {
		r = app.Group(meta.FunctionsBasePath)
	}

	//nolint:exhaustivestruct
	r.Use(recover.New(recover.Config{
		EnableStackTrace: true,
	}))

	//nolint:exhaustivestruct
	r.Use(cors.New(cors.Config{
		AllowOrigins: meta.URL(),
	}))

	r.Use(logger.Middleware(graphQLClient))
	r.Use(auth.Middleware())

	r.Get("/user", routes.UserInfo(graphQLClient))

	r.Use(auth.AssertRegistration(graphQLClient))
	r.Post("/upload", routes.Upload(tikaClient, graphQLClient))

	return app
}
