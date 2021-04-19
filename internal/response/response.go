package response

type QueryError struct {
	Message string `json:"message"`
}

func (q *QueryError) Error() string {
	return q.Message
}

type QueryErrors []*QueryError

type Error struct {
	Path string `json:"path"`
	Err  string `json:"error"`
	Code string `json:"code"`
}

func (e *Error) Error() string {
	return e.Err
}
