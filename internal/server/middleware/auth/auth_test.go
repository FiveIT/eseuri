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
		t.Parallel()

		res := testhelper.DoTestRequest(t, app, testhelper.Request(t, http.MethodGet, nil, c.Token))
		defer res.Body.Close()

		var response struct {
			Error string
		}

		testhelper.DecodeJSON(t, res.Body, &response)

		utils.AssertEqual(t, c.ExpectedStatusCode, res.StatusCode)
		utils.AssertEqual(t, c.ExpectedResponse, response.Error)
	})
}

func TestInvalidJWTs(t *testing.T) {
	t.Parallel()

	app := App(t)
	tests := []testCase{
		{
			Name:               "Malformed",
			Token:              "amSarmale",
			ExpectedStatusCode: http.StatusBadRequest,
			ExpectedResponse:   "missing or malformed token",
		},
		{
			Name: "Invalid",
			//nolint:lll
			Token:              `eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1xWEJrTUY4QWlFaHFuMlBqRUoxRyJ9.eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IlgtSGFzdXJhLURlZmF1bHQtUm9sZSI6InN0dWRlbnQiLCJYLUhhc3VyYS1BbGxvd2VkLVJvbGVzIjpbImFub255bW91cyIsInN0dWRlbnQiXSwiWC1IYXN1cmEtVXNlci1JZCI6IjEifSwiaHR0cHM6Ly9lc2V1cmkuY29tIjp7Imhhc0NvbXBsZXRlZFJlZ2lzdHJhdGlvbiI6dHJ1ZX0sImlzcyI6Imh0dHBzOi8vZXNldXJpLW1hdGVpLWRldi5ldS5hdXRoMC5jb20vIiwic3ViIjoiZ29vZ2xlLW9hdXRoMnwxMDc5NDczMDU2MjI2OTc1NzcxNjgiLCJhdWQiOlsiaHR0cHM6Ly9lc2V1cmktbWF0ZWktZGV2LmV1LmF1dGgwLmNvbS9hcGkvdjIvIiwiaHR0cHM6Ly9lc2V1cmktbWF0ZWktZGV2LmV1LmF1dGgwLmNvbS91c2VyaW5mbyJdLCJpYXQiOjE2MTkwNzk3NzMsImV4cCI6MTYxOTE2NjE3MywiYXpwIjoiMk5UZ095WFJacU9NRVczd2RmVXNmU3FueElhQnc0cmMiLCJzY29wZSI6Im9wZW5pZCBwcm9maWxlIGVtYWlsIn0.nRVlz305wkU5qAR9KkYxNiY1wJxVgk3-JNQBWIs77xcyPXOO35UpGbwfXZBbsAP-sLnQi7B0ARkD1HUOSMtdriGKXD9drSYYa26bhWqcCcO9zREcQADaKd9yAwIok-8oHYWn9Z0YOqv4kKKIJV1piRVzyr9owKN7hEgBd0o5bljz7vzmZpvotbvMjCxgzVnfBHnDZ2TmYxGrA-i_6C4ksP_Co7gNR4BNk_Imy5_a_sFjubbJsqHDymwtrGihHl5IZiwbROayhw8Hr2qyblCmOoay9HbEQUq-ci5dQsfinYXA8ZpzVAnofGacAbOdtDgCAl7pbF3_ZfkSYQd6e-BgSw`,
			ExpectedStatusCode: http.StatusUnauthorized,
			ExpectedResponse:   "invalid or expired token",
		},
	}

	for _, test := range tests {
		test.RunTest(t, app)
	}
}

func TestValidJWT(t *testing.T) {
	t.Parallel()

	ch := make(chan auth.CustomClaims)
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
