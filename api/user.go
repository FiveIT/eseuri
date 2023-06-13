package api

import (
	"net/http"

	"github.com/FiveIT/eseuri/server/server/config"
	"github.com/FiveIT/eseuri/server/server/routes"
	"github.com/FiveIT/eseuri/server/utils"
	"github.com/gofiber/adaptor/v2"
	"github.com/gofiber/fiber/v2"
)

func newUser() http.Handler {
	app := fiber.New(config.Config())

	app.Use(utils.Panic)
	app.Use(utils.Logger)
	app.Use(utils.Auth)

	app.Use(routes.UserInfo(utils.GraphQLClient))

	return adaptor.FiberApp(app)
}

//nolint:gochecknoglobals
var user = newUser()

func User(w http.ResponseWriter, r *http.Request) {
	user.ServeHTTP(w, r)
}
