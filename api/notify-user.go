package api

import (
	"net/http"

	"github.com/FiveIT/eseuri/server/server/config"
	"github.com/FiveIT/eseuri/server/server/routes"
	"github.com/FiveIT/eseuri/server/utils"
	"github.com/gofiber/adaptor/v2"
	"github.com/gofiber/fiber/v2"
)

func newEmail() http.Handler {
	app := fiber.New(config.Config())

	app.Use(utils.Panic)
	app.Use(utils.Logger)
	app.Use(utils.Auth)
	app.Use(utils.AuthAssert)

	app.Post("/", routes.SendEmailStatusWork())

	return adaptor.FiberApp(app)
}

//nolint:gochecknoglobals
var statusWork = newEmail()

func NotifyUser(w http.ResponseWriter, r *http.Request) {
	statusWork.ServeHTTP(w, r)
}
