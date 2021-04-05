package meta

import (
	"github.com/rs/zerolog/log"
)

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
	IsBranchDeply = context == "branch-deploy"
	// FunctionsBasePath is the location of the function handler when deployed to Netlify.
	FunctionsBasePath string
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
