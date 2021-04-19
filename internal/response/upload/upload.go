package upload

import (
	"encoding/json"
	"fmt"

	"github.com/FiveIT/template/internal/response"
)

type WorkResponse struct {
	Response interface{}
}

type Work struct {
	Query struct {
		ID int `json:"id"`
	} `json:"insert_works_one"`
}

//nolint:exhaustivestruct
func (w *WorkResponse) UnmarshalJSON(b []byte) error {
	var r map[string]json.RawMessage

	err := json.Unmarshal(b, &r)
	if err != nil {
		return fmt.Errorf("failed to unmarshal work response: %w", err)
	}

	var (
		data        json.RawMessage
		unmarshaler interface{}
		what        string
	)

	if d, ok := r["data"]; ok {
		data = d
		unmarshaler = &Work{}
		what = "data"
	} else if e, ok := r["errors"]; ok {
		data = e
		unmarshaler = &response.QueryErrors{}
		what = "query errors"
	} else {
		data = b
		unmarshaler = &response.Error{}
		what = "error"
	}

	if err = json.Unmarshal(data, unmarshaler); err != nil {
		return fmt.Errorf("failed to unmarshal %s: %w", what, err)
	}

	if v, ok := unmarshaler.(*response.QueryErrors); ok {
		w.Response = *v
	} else {
		w.Response = unmarshaler
	}

	return nil
}
