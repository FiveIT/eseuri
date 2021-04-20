/*
Package meta provides different constants and functions
used for obtaining endpoints to different external services
or for determining the environment the application
is deployed in.

Checking for Netlify environment:

	// the opposite would mean the app runs in local development
	if meta.IsNetlify {
		log.Println("Deployed on Netlify!")
	}

Obtaining the Hasura GraphQL endpoint and admin secret:

	// or "/v1beta/relay for the GraphQL relay API"
	endpoint := fmt.Sprintf("%s/v1/graphql", meta.HasuraEndpoint)
	secret := meta.HasuraAdminSecret

Obtaining the Apache Tika endpoint:

	endpoint := meta.TikaEndpoint

Obtaining the endpoint of the application's client (for configuring CORS, for example):

	clientURL := meta.URL()

*/
package meta

import (
	"os"

	"github.com/rs/zerolog/log"
)

//nolint:gochecknoglobals
var (
	context string
	url     string
	netlify string
	// IsNetlify specifies if the app was built by Netlify.
	IsNetlify = netlify == "true"
	// IsProduction specifies if the app was built in production mode.
	IsProduction = context == "production"
	// IsDevelopment specifies if the app was built in development mode.
	IsDevelopment = !IsProduction
	// IsDeployPreview specifies if Netlify built the site for pull/merge request preview.
	IsDeployPreview = context == "deploy-preview"
	// IsBranchDeploy specifies if Netlify built the site from a branch different than the site's main production branch.
	IsBranchDeploy = context == "branch-deploy"
	// FunctionsBasePath is the location of the function handler when deployed to Netlify.
	FunctionsBasePath string
	// TikaEndpoint is the endpoint used to connect to the Apache Tika service.
	TikaEndpoint = os.Getenv("TIKA_URL")
	// HasuraEndpoint is the endpoint used to connect to the Hasura GraphQL service.
	HasuraEndpoint = os.Getenv("HASURA_GRAPHQL_ENDPOINT")
	// HasuraAdminSecret is required to make requests to the Hasura GraphQL service.
	HasuraAdminSecret = os.Getenv("HASURA_GRAPHQL_ADMIN_SECRET")
	// HasuraGraphQLPubKey is required to verify Auth0 JWT tokens.
	HasuraGraphQLJWTPubKey = os.Getenv("HASURA_GRAPHQL_JWT_PUB_KEY")
	// Auht0Enpoint is required to verify tokens' issuer.
	Auht0Enpoint = os.Getenv("AUTH0_ENDPOINT")
)

// URL returns the addres at which the client app exists.
func URL() string {
	ret := "http://localhost:3000"
	if IsNetlify {
		ret = url
	}
	return ret
}

func init() {
	log.Info().Str("context", context).Str("client_url", URL()).Msg("Metadata")
}
