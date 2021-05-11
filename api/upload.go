package api

import (
	"net/http"

	"github.com/FiveIT/eseuri/internal/server/config"
	"github.com/FiveIT/eseuri/internal/server/routes"
	"github.com/gofiber/adaptor/v2"
	"github.com/gofiber/fiber/v2"
)

func newUpload() http.Handler {
	app := fiber.New(config.Config())

	app.Use(panicHandler)
	app.Use(loggerHandler)
	app.Use(authHandler)
	app.Use(authAssertHandler)

	app.Post("/", routes.Upload(tikaClient, graphQLClient))

	return adaptor.FiberApp(app)
}

//nolint:gochecknoglobals
var upload = newUpload()

func Upload(w http.ResponseWriter, r *http.Request) {
	upload.ServeHTTP(w, r)
}
