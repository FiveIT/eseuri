package auth0

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"github.com/rs/zerolog/log"
)

var ErrNonOKStatus = errors.New("failed to retrieve token, status code not OK")

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
// can be used to make requests to the API. You can create either a
// registered or unregistered user based on the value of the regiserUser
// parameter which is false by default.
func (a *Auth0) AuthorizationToken(ctx context.Context, registerUser ...bool) (string, error) {
	prefixer := func(message string, err error) error {
		return fmt.Errorf("auth0 OAuth token request: %s: %w", message, err)
	}

	data := url.Values{}
	data.Set("client_id", a.ClientID)
	data.Set("client_secret", a.ClientSecret)
	data.Set("audience", a.Audience)
	data.Set("grant_type", "client_credentials")
	data.Set("registerUser", strconv.FormatBool(len(registerUser) > 0 && registerUser[0]))
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

	if res.StatusCode != http.StatusOK {
		sb := &strings.Builder{}

		_, err := io.Copy(sb, res.Body)
		if err != nil {
			return "", prefixer(fmt.Sprintf("status code %d, request body copying failed", res.StatusCode), err)
		}

		log.Debug().Int("code", res.StatusCode).Str("body", sb.String()).Msg("auth0 token retrieval")

		return "", prefixer(fmt.Sprintf("status code %d", res.StatusCode), ErrNonOKStatus)
	}

	var t struct {
		AccessToken string `json:"access_token"`
		TokenType   string `json:"token_type"`
	}

	if err = json.NewDecoder(res.Body).Decode(&t); err != nil {
		return "", prefixer("couldn't decode response", err)
	}

	return t.TokenType + " " + t.AccessToken, nil
}
