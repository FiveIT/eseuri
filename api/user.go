package api

import (
	"net/http"

	"github.com/FiveIT/eseuri/internal/server/config"
	"github.com/FiveIT/eseuri/internal/server/routes"
	"github.com/gofiber/adaptor/v2"
	"github.com/gofiber/fiber/v2"
)

func newUser() http.Handler {
	app := fiber.New(config.Config())

	app.Use(panicHandler)
	app.Use(loggerHandler)
	app.Use(authHandler)

	app.Get("/", routes.UserInfo(graphQLClient))

	return adaptor.FiberApp(app)
}

//nolint:gochecknoglobals
var user = newUser()

func User(w http.ResponseWriter, r *http.Request) {
	user.ServeHTTP(w, r)
}
