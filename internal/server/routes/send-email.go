package routes

import (
	"net/http"

	"github.com/FiveIT/eseuri/internal/meta"
	"github.com/FiveIT/eseuri/internal/server/helpers"
	"github.com/gofiber/fiber/v2"
	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
)

func SendEmailStatusWork() fiber.Handler {
	return func(c *fiber.Ctx) error {
		var senderInfo helpers.StudentUploaderInfo

		m := mail.NewV3Mail()

		if err := c.BodyParser(&senderInfo); err != nil {
			return helpers.SendError(c, http.StatusBadRequest, "formularul de trimitere email este invalid", err)
		}

		address := "no-reply@eseuri.com"
		name := "Eseuri Bot"
		e := mail.NewEmail(name, address)
		m.SetFrom(e)

		p := mail.NewPersonalization()

		if senderInfo.StatusLucrare == "accepted" {
			m.SetTemplateID("d-709b5b58f80543559068014c4e689bfc")

			link := "https://eseuri.com/" + senderInfo.WorkID
			p.SetDynamicTemplateData("link", link)
		} else {
			m.SetTemplateID("d-069856a4edc04fd7a0b5ba1709a09ebb")
		}

		to := mail.NewEmail(senderInfo.NumeleElevului, senderInfo.EmailElev)
		p.AddTos(to)

		p.SetDynamicTemplateData("first_name", senderInfo.NumeleElevului)

		request := sendgrid.GetRequest(meta.SendgridKey, "/v3/mail/send", "https://api.sendgrid.com")
		request.Method = "POST"

		var Body = mail.GetRequestBody(m)

		request.Body = Body
		response, err := sendgrid.API(request)

		if err != nil {
			return err
		}

		return c.SendStatus(response.StatusCode)
	}
}
