package server_test

import (
	"bytes"
	"context"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/FiveIT/template/internal/meta"
	"github.com/FiveIT/template/internal/server"
	"github.com/gofiber/fiber/v2/utils"
)

//nolint:gochecknoglobals
var token string

func TestMain(m *testing.M) {
	var err error
	token, err = meta.Auth0.AuthorizationToken(context.Background())

	if err != nil {
		log.Fatalf("Couldn't get Auth0 access token: %v", err)
	}

	os.Exit(m.Run())
}

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
	request, err := newfileUploadRequest(token, "https://google.com/upload", extraParams, "document", "./testOK.odt")

	if err != nil {
		t.Fatal(err)
	}

	app := server.New()
	resp, err := app.Test(request)

	if err != nil {
		t.Fatal(err)
	}

	body := &bytes.Buffer{}
	_, err = body.ReadFrom(resp.Body)

	if err != nil {
		t.Fatal(err)
	}

	resp.Body.Close()
	// log.Println(body)
	utils.AssertEqual(t, 200, resp.StatusCode, "Get 200")
}

func TestUploadBadFile(t *testing.T) {
	t.Parallel()

	extraParams := map[string]string{
		"titlu":          "1",
		"tipul_lucrarii": "essay",
	}
	request, err := newfileUploadRequest(token, "https://google.com/upload", extraParams, "document", "./testBAD.txt")

	if err != nil {
		t.Fatal(err)
	}

	app := server.New()
	resp, err := app.Test(request)

	if err != nil {
		t.Fatal(err)
	} else {
		body := &bytes.Buffer{}
		_, err := body.ReadFrom(resp.Body)
		if err != nil {
			t.Fatal(err)
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
	request, err := newfileUploadRequest("lol", "https://google.com/upload", extraParams, "document", "./testOK.odt")

	if err != nil {
		t.Fatal(err)
	}

	app := server.New()
	resp, err := app.Test(request)

	if err != nil {
		t.Fatal(err)
	} else {
		body := &bytes.Buffer{}
		_, err := body.ReadFrom(resp.Body)
		if err != nil {
			t.Fatal(err)
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
	request, err := newfileUploadRequest(token, "https://google.com/upload", extraParams, "document", "./testOK2.odt")

	if err != nil {
		t.Fatal(err)
	}

	app := server.New()
	resp, err := app.Test(request)

	if err != nil {
		t.Fatal(err)
	} else {
		body := &bytes.Buffer{}
		_, err := body.ReadFrom(resp.Body)
		if err != nil {
			t.Fatal(err)
		}
		resp.Body.Close()
		log.Println(body)
		utils.AssertEqual(t, 200, resp.StatusCode, "Get 200")
	}
}
