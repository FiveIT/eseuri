package utils

import (
	"github.com/FiveIT/eseuri/internal/server/middleware/auth"
	"github.com/FiveIT/eseuri/internal/server/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

//nolint:gochecknoglobals
var (
	//nolint:exhaustivestruct
	Panic = recover.New(recover.Config{
		EnableStackTrace: true,
	})
	Logger     = logger.Middleware(GraphQLClient)
	Auth       = auth.Middleware()
	AuthAssert = auth.AssertRegistration(GraphQLClient)
)
