package api

import (
	"net/http"

	"github.com/FiveIT/eseuri/internal/server"
	"github.com/gofiber/adaptor/v2"
)

//nolint:gochecknoglobals
var handlerProxy = adaptor.FiberApp(server.New())

func Handler(w http.ResponseWriter, r *http.Request) {
	handlerProxy(w, r)
}
