package request

import (
	"bytes"
	"context"
	"fmt"
	"mime/multipart"
	"net/http"
	"testing"

	"github.com/FiveIT/eseuri/pkg/request/internal"
	multiparthelpers "github.com/FiveIT/eseuri/pkg/request/internal/multipart"
)

type MultipartData struct {
	Client        *http.Client
	Authorization string
	Header        map[string]interface{}
	Fields        map[string]interface{}
	Test          testing.TB
	TestFn        func(*http.Request) (*http.Response, error)
}

func Multipart(ctx context.Context, method string, target string, data MultipartData) (*http.Response, error) {
	if data.Test != nil {
		data.Test.Helper()
	}

	w := &bytes.Buffer{}
	m := multipart.NewWriter(w)

	for fieldname, value := range data.Fields {
		if err := multiparthelpers.Write(m, fieldname, value); err != nil {
			//nolint:wrapcheck
			return nil, err
		}
	}

	m.Close()

	req, err := internal.NewRequest(internal.Data{
		Context:       ctx,
		Method:        method,
		Target:        target,
		ContentType:   m.FormDataContentType(),
		Authorization: data.Authorization,
		Body:          w,
		Header:        data.Header,
		Test:          data.Test,
	})
	if err != nil {
		//nolint:wrapcheck
		return nil, err
	}

	var res *http.Response
	if data.TestFn != nil {
		res, err = data.TestFn(req)
	} else {
		c := data.Client
		if c == nil {
			c = http.DefaultClient
		}
		res, err = c.Do(req)
	}

	if err != nil {
		return nil, fmt.Errorf("request: failed: %w", err)
	}

	return res, nil
}

// TODO: tests
