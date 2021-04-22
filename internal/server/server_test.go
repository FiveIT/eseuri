package server_test

import (
	"bytes"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/FiveIT/template/internal/server"
	"github.com/gofiber/fiber/v2/utils"
)

const (
	badToken  = "laceamnevoiedeverificarisisemnaturicrypto101"
	goodToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1xWEJrTUY4QWlFaHFuMlBqRUoxRyJ9.eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IlgtSGFzdXJhLURlZmF1bHQtUm9sZSI6InN0dWRlbnQiLCJYLUhhc3VyYS1BbGxvd2VkLVJvbGVzIjpbImFub255bW91cyIsInN0dWRlbnQiXSwiWC1IYXN1cmEtVXNlci1JZCI6IjEifSwiaHR0cHM6Ly9lc2V1cmkuY29tIjp7Imhhc0NvbXBsZXRlZFJlZ2lzdHJhdGlvbiI6dHJ1ZX0sImlzcyI6Imh0dHBzOi8vZXNldXJpLW1hdGVpLWRldi5ldS5hdXRoMC5jb20vIiwic3ViIjoiZ29vZ2xlLW9hdXRoMnwxMDc5NDczMDU2MjI2OTc1NzcxNjgiLCJhdWQiOlsiaHR0cHM6Ly9lc2V1cmktbWF0ZWktZGV2LmV1LmF1dGgwLmNvbS9hcGkvdjIvIiwiaHR0cHM6Ly9lc2V1cmktbWF0ZWktZGV2LmV1LmF1dGgwLmNvbS91c2VyaW5mbyJdLCJpYXQiOjE2MTkwNzk3NzMsImV4cCI6MTYxOTE2NjE3MywiYXpwIjoiMk5UZ095WFJacU9NRVczd2RmVXNmU3FueElhQnc0cmMiLCJzY29wZSI6Im9wZW5pZCBwcm9maWxlIGVtYWlsIn0.nRVlz305wkU5qAR9KkYxNiY1wJxVgk3-JNQBWIs77xcyPXOO35UpGbwfXZBbsAP-sLnQi7B0ARkD1HUOSMtdriGKXD9drSYYa26bhWqcCcO9zREcQADaKd9yAwIok-8oHYWn9Z0YOqv4kKKIJV1piRVzyr9owKN7hEgBd0o5bljz7vzmZpvotbvMjCxgzVnfBHnDZ2TmYxGrA-i_6C4ksP_Co7gNR4BNk_Imy5_a_sFjubbJsqHDymwtrGihHl5IZiwbROayhw8Hr2qyblCmOoay9HbEQUq-ci5dQsfinYXA8ZpzVAnofGacAbOdtDgCAl7pbF3_ZfkSYQd6e-BgSw"
)

func Test200Response(t *testing.T) {
	t.Parallel()

	app := server.New()

	req := httptest.NewRequest("GET", "/", nil)
	res, err := app.Test(req)
	res.Body.Close()
	utils.AssertEqual(t, nil, err, "Test connection to /")
	utils.AssertEqual(t, 200, res.StatusCode, "Get 200")
}

func newfileUploadRequest(token string, uri string, params map[string]string, paramName, path string) (*http.Request, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile(paramName, filepath.Base(path))

	if err != nil {
		return nil, err
	}

	_, _ = io.Copy(part, file)

	for key, val := range params {
		_ = writer.WriteField(key, val)
	}

	err = writer.Close()
	if err != nil {
		return nil, err
	}

	req := httptest.NewRequest("POST", uri, body)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	req.Header.Set("Authorization", token)

	return req, err
}

func TestUploadGoodFile(t *testing.T) {
	t.Parallel()

	extraParams := map[string]string{
		"titlu":          "1",
		"tipul_lucrarii": "essay",
	}
	request, err := newfileUploadRequest(goodToken, "https://google.com/upload", extraParams, "document", "./testOK.odt")

	if err != nil {
		log.Fatal(err)
	}

	app := server.New()
	resp, err := app.Test(request)

	if err != nil {
		log.Fatal(err)
	} else {
		body := &bytes.Buffer{}
		_, err := body.ReadFrom(resp.Body)
		if err != nil {
			log.Fatal(err)
		}
		resp.Body.Close()
		// log.Println(body)
		utils.AssertEqual(t, 200, resp.StatusCode, "Get 200")
	}
}

func TestUploadBadFile(t *testing.T) {
	t.Parallel()

	extraParams := map[string]string{
		"titlu":          "1",
		"tipul_lucrarii": "essay",
	}
	request, err := newfileUploadRequest(goodToken, "https://google.com/upload", extraParams, "document", "./testBAD.txt")

	if err != nil {
		log.Fatal(err)
	}

	app := server.New()
	resp, err := app.Test(request)

	if err != nil {
		log.Fatal(err)
	} else {
		body := &bytes.Buffer{}
		_, err := body.ReadFrom(resp.Body)
		if err != nil {
			log.Fatal(err)
		}
		resp.Body.Close()
		// log.Println(body)
		utils.AssertEqual(t, 400, resp.StatusCode, "Get 400")
	}
}

func TestUploadBadOrExpiredToken(t *testing.T) {
	t.Parallel()

	extraParams := map[string]string{
		"titlu":          "1",
		"tipul_lucrarii": "essay",
	}
	request, err := newfileUploadRequest(badToken, "https://google.com/upload", extraParams, "document", "./testOK.odt")

	if err != nil {
		log.Fatal(err)
	}

	app := server.New()
	resp, err := app.Test(request)

	if err != nil {
		log.Fatal(err)
	} else {
		body := &bytes.Buffer{}
		_, err := body.ReadFrom(resp.Body)
		if err != nil {
			log.Fatal(err)
		}
		resp.Body.Close()
		// log.Println(body)
		utils.AssertEqual(t, 401, resp.StatusCode, "Get 401")
	}
}

func TestUploadGoodFileAndProfessor(t *testing.T) {
	t.Parallel()

	extraParams := map[string]string{
		"titlu":          "1",
		"tipul_lucrarii": "essay",
		"corector_cerut": "2",
	}
	request, err := newfileUploadRequest(goodToken, "https://google.com/upload", extraParams, "document", "./testOK2.odt")

	if err != nil {
		log.Fatal(err)
	}

	app := server.New()
	resp, err := app.Test(request)

	if err != nil {
		log.Fatal(err)
	} else {
		body := &bytes.Buffer{}
		_, err := body.ReadFrom(resp.Body)
		if err != nil {
			log.Fatal(err)
		}
		resp.Body.Close()
		log.Println(body)
		utils.AssertEqual(t, 200, resp.StatusCode, "Get 200")
	}
}
