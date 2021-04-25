package multipart

import (
	"fmt"
	"io"
	"io/fs"
	"os"
)

var (
	ErrDirectoriesNotSupported = errorf("directories not supported")
	ErrInvalidFormat           = errorf("invalid field format")
)

func errorf(format string, args ...interface{}) error {
	//nolint:goerr113
	return fmt.Errorf("request: multipart: "+format, args...)
}

func handleClose(c io.Closer, fieldname string, err *error) {
	if *err != nil {
		return
	}

	if e := c.Close(); e != nil {
		*err = errorf("failed to close reader at field %q: %w", fieldname, e)
	}
}

func getFilename(f fs.File) (string, error) {
	if o, ok := f.(*os.File); ok {
		return o.Name(), nil
	}

	stat, err := f.Stat()
	if err != nil {
		return "", errorf("failed to stat file: %w", err)
	}

	if stat.IsDir() {
		return "", ErrDirectoriesNotSupported
	}

	return stat.Name(), nil
}
