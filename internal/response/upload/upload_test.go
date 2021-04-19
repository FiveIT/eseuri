//nolint:gochecknoglobals
package upload_test

import (
	"embed"
	"encoding/json"
	"fmt"
	"path"
	"strings"
	"testing"

	"github.com/FiveIT/template/internal/response"
	"github.com/FiveIT/template/internal/response/upload"
)

//go:embed testdata/*
var data embed.FS

func decode(tb testing.TB, name string) upload.WorkResponse {
	tb.Helper()

	file, err := data.Open(path.Join("testdata", name))
	if err != nil {
		tb.Fatalf("Failed to open file %s: %v", name, err)
	}

	var r upload.WorkResponse
	if err = json.NewDecoder(file).Decode(&r); err != nil {
		tb.Fatalf("Failed to unmarshal file %s: %v", name, err)
	}

	tb.Logf("Decoded response: %+v", data)

	return r
}

func TestUnmarshalSuccess(t *testing.T) {
	t.Parallel()

	res := decode(t, "success.json")

	data, ok := res.Response.(*upload.Work)
	if !ok {
		t.Fatalf("Expected response to be of type %T, got %T", data, res.Response)
	}

	if data.Query.ID != 1 {
		t.Fatalf("Response unmarshaled incorrectly")
	}
}

func TestUnmarshalQueryError(t *testing.T) {
	t.Parallel()

	res := decode(t, "queryerrors.json")

	errors, ok := res.Response.(response.QueryErrors)
	if !ok {
		t.Fatalf("Expected response to be of type %T, got %T", errors, res.Response)
	}

	if len(errors) != 1 || !strings.Contains(errors[0].Message, `"unique_content"`) {
		t.Fatal("Response unmarshaled incorrectly")
	}
}

func TestUnmarshalError(t *testing.T) {
	t.Parallel()

	res := decode(t, "error.json")

	err, ok := res.Response.(*response.Error)
	if !ok {
		t.Fatalf("Expected response to be of type %T, got %T", err, res.Response)
	}

	if err.Code != "not-found" {
		t.Fatal("Response unmarshaled incorrectly")
	}
}

func ExampleWorkResponse() {
	file, _ := data.Open(path.Join("testdata", "success.json"))

	var r upload.WorkResponse

	_ = json.NewDecoder(file).Decode(&r)

	switch v := r.Response.(type) {
	case *upload.Work:
		fmt.Println(v.Query.ID)

	// errors implement the Error interface
	case response.QueryErrors:
		fmt.Println(v[0])
	case *response.Error:
		fmt.Println(v)
	}
	// Output: 1
}
