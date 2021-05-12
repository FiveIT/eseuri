package utils

import (
	"github.com/FiveIT/eseuri/internal/meta"
	"github.com/google/go-tika/tika"
	"github.com/machinebox/graphql"
)

//nolint:gochecknoglobals
var (
	TikaClient    = tika.NewClient(nil, meta.TikaEndpoint)
	GraphQLClient = graphql.NewClient(meta.HasuraEndpoint + "/v1/graphql")
)
