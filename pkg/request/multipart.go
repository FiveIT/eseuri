package request

import (
	"context"
	"fmt"
	"io"
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

	body, w := io.Pipe()
	m := multipart.NewWriter(w)

	req, err := internal.NewRequest(internal.Data{
		Context:       ctx,
		Method:        method,
		Target:        target,
		ContentType:   m.FormDataContentType(),
		Authorization: data.Authorization,
		Body:          body,
		Header:        data.Header,
		Test:          data.Test,
	})
	if err != nil {
		//nolint:wrapcheck
		return nil, err
	}

	errch := make(chan error)

	go func() {
		defer close(errch)
		defer internal.HandleClose(w, errch)
		defer internal.HandleClose(m, errch)

		for fieldname, value := range data.Fields {
			if err := multiparthelpers.Write(m, fieldname, value); err != nil {
				errch <- err

				return
			}
		}
	}()

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

	if err = <-errch; err != nil {
		return nil, err
	}

	return res, nil
}

// TODO: tests
