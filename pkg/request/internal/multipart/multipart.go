package multipart

import (
	"bytes"
	"encoding"
	"fmt"
	"io"
	"io/fs"
	"mime/multipart"
)

func getWritableValue(value interface{}) (interface{}, error) {
	var (
		b   []byte
		err error
	)

	switch v := value.(type) {
	case encoding.BinaryMarshaler:
		b, err = v.MarshalBinary()
		if err != nil {
			return nil, errorf("failed to marshal field %q into binary: %w", err)
		}
	case encoding.TextMarshaler:
		b, err = v.MarshalText()
		if err != nil {
			return nil, errorf("failed to marshal field %q into text: %w", err)
		}
	case fmt.Stringer:
		return v.String(), nil
	case string, io.Reader:
		return v, nil
	default:
		return fmt.Sprintf("%v", value), nil
	}

	return bytes.NewReader(b), nil
}

func writeToForm(m *multipart.Writer, fieldname string, value interface{}) (err error) {
	switch v := value.(type) {
	case string:
		if err := m.WriteField(fieldname, v); err != nil {
			return errorf("failed to write field %q: %w", err)
		}

		return nil
	case io.Reader:
		if c, ok := v.(io.Closer); ok {
			defer handleClose(c, fieldname, &err)
		}

		var (
			w io.Writer
			n int64
		)

		if f, ok := v.(fs.File); ok {
			filename, err := getFilename(f)
			if err != nil {
				return errorf("failed to process form file at field %q: %w", err)
			}

			if w, err = m.CreateFormFile(fieldname, filename); err != nil {
				return errorf("failed to create form file %q for field %q: %w", filename, fieldname, err)
			}

			v = f
		} else {
			w, err = m.CreateFormField(fieldname)
			if err != nil {
				return errorf("failed to create form field %q: %w", fieldname, err)
			}
		}

		if n, err = io.Copy(w, v); err != nil {
			return errorf("failed to copy from reader at field %q (%d bytes copied): %w", fieldname, n, err)
		}

		return nil
	}

	return ErrInvalidFormat
}

func Write(m *multipart.Writer, fieldname string, value interface{}) error {
	v, err := getWritableValue(value)
	if err != nil {
		return err
	}

	return writeToForm(m, fieldname, v)
}
