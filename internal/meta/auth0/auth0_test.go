package auth0_test

import (
	"context"
	"testing"

	"github.com/FiveIT/template/internal/meta"
)

func TestGetAuthorizationToken(t *testing.T) {
	t.Parallel()

	token, err := meta.Auth0.GetAuthorizationToken(context.Background())
	if err != nil {
		t.Fatalf("Failed to get token: %v", err)
	}

	t.Logf(token)
}