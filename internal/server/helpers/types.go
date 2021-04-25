package helpers

type WorkFormInput struct {
	Type               string `form:"type"`
	SubjectID          int    `form:"subject"`
	RequestedTeacherID int    `form:"requestedTeacher"`
}
