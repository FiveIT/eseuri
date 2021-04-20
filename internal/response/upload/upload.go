package upload

import (
	"github.com/FiveIT/template/internal/response/internal"
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
func (w *WorkResponse) UnmarshalJSON(b []byte) (err error) {
	w.Response, err = internal.UnmarshalJSON(b, &Work{})

	return
}
