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
func App(tb testing.TB) *fiber.App {
	tb.Helper()

	return testhelper.App(tb, "hello", logger.Middleware(nil), auth.Middleware())
}

func TestInvalidJWT(t *testing.T) {
	t.Parallel()

	app := App(t)
	req := testhelper.Request(t, http.MethodGet, nil, "amSarmale")

	res := testhelper.DoTestRequest(t, app, req)
	defer res.Body.Close()

	var response struct {
		Error string
	}

	testhelper.DecodeJSON(t, res.Body, &response)

	utils.AssertEqual(t, http.StatusUnauthorized, res.StatusCode)
	utils.AssertEqual(t, "invalid or expired token", response.Error)
}

func TestValidJWT(t *testing.T) {
	t.Parallel()

	app := App(t)
	ch := make(chan auth.CustomClaims)

	app.Use(func(c *fiber.Ctx) error {
		ch <- c.Locals("claims").(auth.CustomClaims)

		return c.Next()
	})

	jwt := testhelper.JWT(t, true)
	req := testhelper.Request(t, http.MethodGet, nil, jwt)

	res := testhelper.DoTestRequest(t, app, req)
	defer res.Body.Close()

	body := testhelper.ReadString(t, res.Body)

	utils.AssertEqual(t, http.StatusOK, res.StatusCode)
	utils.AssertEqual(t, "hello", body)

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
