package api

import (
	"net/http"

	"github.com/FiveIT/eseuri/internal/server/config"
	"github.com/FiveIT/eseuri/internal/server/routes"
	"github.com/FiveIT/eseuri/internal/utils"
	"github.com/gofiber/adaptor/v2"
	"github.com/gofiber/fiber/v2"
)

func newUpload() http.Handler {
	app := fiber.New(config.Config())

	app.Use(utils.Panic)
	app.Use(utils.Logger)
	app.Use(utils.Auth)
	app.Use(utils.AuthAssert)

	app.Post("/", routes.Upload(utils.TikaClient, utils.GraphQLClient))

	return adaptor.FiberApp(app)
}

//nolint:gochecknoglobals
var upload = newUpload()

func Upload(w http.ResponseWriter, r *http.Request) {
	upload.ServeHTTP(w, r)
}
