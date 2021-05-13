package helpers

type WorkFormInput struct {
	Type               string `form:"type"`
	SubjectID          int    `form:"subject"`
	RequestedTeacherID int    `form:"requestedTeacher"`
}

type StudentUploaderInfo struct {
	StatusLucrare  string `form:"status"`
	NumeleElevului string `form:"name"`
	EmailElev      string `form:"email"`
	URL            string `form:"url"`
}
