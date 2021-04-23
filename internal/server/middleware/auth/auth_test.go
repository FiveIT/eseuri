package auth_test

import (
	"net/http"
	"testing"

	"github.com/FiveIT/template/internal/server/middleware/auth"
	"github.com/FiveIT/template/internal/server/middleware/logger"
	"github.com/FiveIT/template/internal/testhelper"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/utils"
)

// App returns a Fiber App with the auth middleware applied,
// so it can be used for testing purposes.
func App(tb testing.TB, customClaims ...chan auth.CustomClaims) *fiber.App {
	tb.Helper()

	claimsMiddleware := func(c *fiber.Ctx) error {
		for _, ch := range customClaims {
			ch <- c.Locals("claims").(auth.CustomClaims)
			close(ch)

			break
		}

		return c.Next()
	}

	return testhelper.App(tb, logger.Middleware(nil), auth.Middleware(), claimsMiddleware)
}

type testCase struct {
	Name               string
	Token              string
	ExpectedStatusCode int
	ExpectedResponse   string
}

func (c testCase) RunTest(t *testing.T, app *fiber.App) {
	t.Helper()

	t.Run(c.Name, func(t *testing.T) {
	})
}

func TestInvalidJWT(t *testing.T) {
	t.Parallel()

	res := testhelper.DoTestRequest(t, App(t), testhelper.Request(t, http.MethodGet, nil, "amSarmale"))
	defer res.Body.Close()

	var response struct {
		Error string
	}

	testhelper.DecodeJSON(t, res.Body, &response)

	utils.AssertEqual(t, http.StatusBadRequest, res.StatusCode)
	utils.AssertEqual(t, "missing or malformed token", response.Error)
}

func TestValidJWT(t *testing.T) {
	t.Parallel()

	ch := make(chan auth.CustomClaims, 1)
	app := App(t, ch)

	jwt := testhelper.JWT(t, true)
	req := testhelper.Request(t, http.MethodGet, nil, jwt)

	res := testhelper.DoTestRequest(t, app, req)
	defer res.Body.Close()

	utils.AssertEqual(t, http.StatusNoContent, res.StatusCode)

	if claims := <-ch; (claims.Role != "student" && claims.Role != "teacher") || claims.UserID == 0 {
		t.Fatalf("Invalid custom claims: %+v", claims)
	}
}

func TestValidJWTUnregisteredUser(t *testing.T) {
	t.Parallel()

	app := App(t)
	jwt := testhelper.JWT(t)
	req := testhelper.Request(t, http.MethodGet, nil, jwt)

	res := testhelper.DoTestRequest(t, app, req)
	defer res.Body.Close()

	var response struct {
		Error string
	}

	testhelper.DecodeJSON(t, res.Body, &response)

	utils.AssertEqual(t, http.StatusUnauthorized, res.StatusCode)
	utils.AssertEqual(t, "unregistered user", response.Error)
}
