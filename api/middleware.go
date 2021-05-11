package api

import (
	"github.com/FiveIT/eseuri/internal/server/middleware/auth"
	"github.com/FiveIT/eseuri/internal/server/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

//nolint:gochecknoglobals
var (
	//nolint:exhaustivestruct
	panicHandler = recover.New(recover.Config{
		EnableStackTrace: true,
	})
	loggerHandler     = logger.Middleware(graphQLClient)
	authHandler       = auth.Middleware()
	authAssertHandler = auth.AssertRegistration(graphQLClient)
)
