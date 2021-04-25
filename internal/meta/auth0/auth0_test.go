package auth0_test

import (
	"context"
	"strings"
	"testing"

	"github.com/FiveIT/eseuri/internal/meta"
)

func TestGetAuthorizationToken(t *testing.T) {
	t.Parallel()

	token, err := meta.Auth0.AuthorizationToken(context.Background())
	if err != nil {
		t.Fatalf("Failed to get token: %v", err)
	}

	t.Logf(token)

	if !strings.HasPrefix(token, "Bearer ") {
		t.Fatal(`Expected "Bearer" prefix`)
	}
}
