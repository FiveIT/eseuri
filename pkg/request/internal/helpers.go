package internal

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

type Data struct {
	Context       context.Context
	Method        string
	Target        string
	ContentType   string
	Authorization string
	Body          io.Reader
	Header        map[string]interface{}
	Test          testing.TB
}

func NewRequest(data Data) (*http.Request, error) {
	var (
		req *http.Request
		err error
	)

	if data.Test != nil {
		data.Test.Helper()
		req = httptest.NewRequest(data.Method, data.Target, data.Body)
	} else {
		if data.Context == nil {
			data.Context = context.Background()
		}
		req, err = http.NewRequestWithContext(data.Context, data.Method, data.Target, data.Body)
		if err != nil {
			return nil, fmt.Errorf("request: failed to create request: %w", err)
		}
	}

	if data.ContentType != "" {
		req.Header.Set("Content-Type", data.ContentType)
	}

	if data.Authorization != "" {
		req.Header.Set("Authorization", data.Authorization)
	}

	for key, value := range data.Header {
		req.Header.Set(key, fmt.Sprintf("%v", value))
	}

	return req, nil
}

func HandleClose(c io.Closer, ch chan error) {
	err := c.Close()

	select {
	case cerr := <-ch:
		ch <- cerr
	default:
		ch <- err
	}
}
