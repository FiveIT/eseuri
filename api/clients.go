package api

import (
	"github.com/FiveIT/eseuri/internal/meta"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
)

//nolint:gochecknoglobals
var (
	tikaClient    = tika.NewClient(nil, meta.TikaEndpoint)
	graphQLClient = graphql.NewClient(meta.HasuraEndpoint + "/v1/graphql")
)
