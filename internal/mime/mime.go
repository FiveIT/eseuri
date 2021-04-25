/*
Package mime contains common MIME-types.
*/
package mime

const (
	a = "application/"
	i = "image/"
	t = "text/"

	DOC  = a + "msword"
	DOCX = a + "vnd.openxmlformats-officedocument.wordprocessingml.document"
	JPEG = i + "jpeg"
	ODT  = a + "vnd.oasis.opendocument.text"
	PNG  = i + "png"
	PDF  = a + "pdf"
	RTF  = a + "rtf"
	TXT  = t + "plain"
)
