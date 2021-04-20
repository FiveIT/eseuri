package internal

import (
	"encoding/json"
	"fmt"

	"github.com/FiveIT/template/internal/response"
)

//nolint:exhaustivestruct
// UnmarshalJSON is used to unmarshal a Hasura GraphQL response.
// v is the struct in which the successful response should be unmarshaled.
// The function returns the given struct with the unmarshaled data,
// or a suitable error struct.
func UnmarshalJSON(b []byte, v interface{}) (interface{}, error) {
	var r map[string]json.RawMessage

	err := json.Unmarshal(b, &r)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	var (
		data json.RawMessage
		what = "data"
	)

	if d, ok := r["data"]; ok {
		data = d
	} else if e, ok := r["errors"]; ok {
		data = e
		v = &response.QueryErrors{}
		what = "query errors"
	} else {
		data = b
		v = &response.Error{}
		what = "error"
	}

	if err = json.Unmarshal(data, v); err != nil {
		return nil, fmt.Errorf("failed to unmarshal %s: %w", what, err)
	}

	if v, ok := v.(*response.QueryErrors); ok {
		return *v, nil
	}

	return v, nil
}
