package main

import (
	"context"

	"github.com/FiveIT/template/internal/meta"
	"github.com/FiveIT/template/internal/server"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	fiberadapter "github.com/awslabs/aws-lambda-go-api-proxy/fiber"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {
	debugLevel := zerolog.TraceLevel
	if meta.IsProduction {
		debugLevel = zerolog.ErrorLevel
	}
	zerolog.SetGlobalLevel(debugLevel)

	app := server.New()

	if meta.IsNetlify {
		proxy := fiberadapter.New(app)

		lambda.Start(func(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
			return proxy.ProxyWithContext(ctx, req)
		})
	} else {
		if err := app.Listen(":4000"); err != nil {
			log.Error().Err(err).Msg("Failed to start server!")
		}
	}
}
