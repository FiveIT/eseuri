package api

import (
	"net/http"

	"github.com/FiveIT/eseuri/server/server/config"
	"github.com/FiveIT/eseuri/server/server/routes"
	"github.com/FiveIT/eseuri/server/utils"
	"github.com/gofiber/adaptor/v2"
	"github.com/gofiber/fiber/v2"
)

func newUpload() http.Handler {
	app := fiber.New(config.Config())

	app.Use(utils.Panic)
	app.Use(utils.Logger)
	app.Use(utils.Auth)
	app.Use(utils.AuthAssert)

	app.Use(routes.Upload(utils.TikaClient, utils.GraphQLClient))

	return adaptor.FiberApp(app)
}

//nolint:gochecknoglobals
var upload = newUpload()

func Upload(w http.ResponseWriter, r *http.Request) {
	upload.ServeHTTP(w, r)
}
