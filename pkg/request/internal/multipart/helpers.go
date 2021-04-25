package multipart

import (
	"fmt"
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
