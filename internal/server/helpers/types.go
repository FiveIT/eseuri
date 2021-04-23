package helpers

import "mime/multipart"

type WorkFormInput struct {
	File               *multipart.FileHeader `form:"file"`
	Type               string                `form:"type"`
	SubjectID          int                   `form:"subject"`
	RequestedTeacherID int                   `form:"requestedTeacher"`
}
