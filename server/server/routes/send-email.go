package routes

import (
	"fmt"
	"net/http"

	"github.com/FiveIT/eseuri/server/meta"
	"github.com/FiveIT/eseuri/server/server/helpers"
	"github.com/gofiber/fiber/v2"
	"github.com/rs/zerolog"
	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
)

func SendEmailStatusWork() fiber.Handler {
	return func(c *fiber.Ctx) error {
		var senderInfo helpers.StudentUploaderInfo

		logger := c.Locals("logger").(zerolog.Logger)
		m := mail.NewV3Mail()

		if err := c.BodyParser(&senderInfo); err != nil {
			return helpers.SendError(c, http.StatusBadRequest, "formularul de trimitere email este invalid", err)
		}

		address := "no-reply@eseuri.com"
		name := "Eseuri"
		e := mail.NewEmail(name, address)
		m.SetFrom(e)

		p := mail.NewPersonalization()

		if senderInfo.StatusLucrare == "approved" {
			m.SetTemplateID("d-709b5b58f80543559068014c4e689bfc")
		} else {
			m.SetTemplateID("d-069856a4edc04fd7a0b5ba1709a09ebb")
		}
		to := mail.NewEmail(senderInfo.NumeleElevului, senderInfo.EmailElev)
		p.AddTos(to)
		p.SetDynamicTemplateData("link", senderInfo.URL)

		p.SetDynamicTemplateData("first_name", senderInfo.NumeleElevului)

		m.AddPersonalizations(p)

		request := sendgrid.GetRequest(meta.SendgridKey, "/v3/mail/send", "https://api.sendgrid.com")
		request.Method = "POST"

		var Body = mail.GetRequestBody(m)

		request.Body = Body
		response, err := sendgrid.MakeRequest(request)

		if err != nil {
			return fmt.Errorf("failed to send email: %w", err)
		}

		logger.Debug().Int("status", response.StatusCode).Msg("sengrid response code")
		logger.Debug().Str("body", response.Body).Msg("sengrid response body")

		return c.SendStatus(fiber.StatusOK)
	}
}
