package main

import (
	"context"

	"github.com/FiveIT/eseuri/internal/meta"
	"github.com/FiveIT/eseuri/internal/server"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	fiberadapter "github.com/awslabs/aws-lambda-go-api-proxy/fiber"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {
	logLevel := zerolog.TraceLevel
	if meta.IsProduction {
		logLevel = zerolog.ErrorLevel
	}

	zerolog.SetGlobalLevel(logLevel)

	app := server.New()

	if meta.IsNetlify {
		proxy := fiberadapter.New(app)

		lambda.Start(func(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
			return proxy.ProxyWithContext(ctx, req)
		})
	} else {
		if err := app.Listen(":4000"); err != nil {
			log.Err(err).Msg("Failed to start server!")
		}
	}
}
