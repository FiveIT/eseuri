package auth0

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
)

type Auth0 struct {
	Domain       string
	ClientID     string
	ClientSecret string
	Audience     string
}

func (a *Auth0) oAuthURL() string {
	return "https://" + a.Domain + "/oauth/token"
}

// AuthorizationToken obtains a JWT token from Auth0 that
// can be used to make requests to the API. The Auth0 rule also
// creates an registered user, so the token can be used in server tests.
func (a *Auth0) AuthorizationToken(ctx context.Context) (string, error) {
	prefixer := func(message string, err error) error {
		return fmt.Errorf("auth0 OAuth token request: %s: %w", message, err)
	}

	data := url.Values{}
	data.Set("client_id", a.ClientID)
	data.Set("client_secret", a.ClientSecret)
	data.Set("audience", a.Audience)
	data.Set("grant_type", "client_credentials")
	b := strings.NewReader(data.Encode())

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, a.oAuthURL(), b)
	if err != nil {
		return "", prefixer("couldn't create request object", err)
	}

	req.Header.Add("Cache-Control", "no-cache")
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", prefixer("post failed", err)
	}
	defer res.Body.Close()

	var t struct {
		AccessToken string `json:"access_token"`
		TokenType   string `json:"token_type"`
	}

	if err = json.NewDecoder(res.Body).Decode(&t); err != nil {
		return "", prefixer("couldn't decode response", err)
	}

	return t.TokenType + " " + t.AccessToken, nil
}
