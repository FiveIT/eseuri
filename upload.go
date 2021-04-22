package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/FiveIT/template/internal/meta"
)

const token = `ha you thought`

func main() {
	url := fmt.Sprintf("https://%s/api/v2/hooks", meta.Auth0.Domain)
	b, _ := ioutil.ReadFile("scripts/hook.js")

	payload := strings.NewReader(fmt.Sprintf("{ \"name\": %q, \"script\": %q, \"triggerId\": %q }", "Hasura login", string(b), "credentials-exchange"))

	req, _ := http.NewRequest("POST", url, payload)

	req.Header.Add("content-type", "application/json")
	req.Header.Add("authorization", "Bearer "+token)
	req.Header.Add("cache-control", "no-cache")

	res, _ := http.DefaultClient.Do(req)

	defer res.Body.Close()
	body, _ := ioutil.ReadAll(res.Body)

	fmt.Println(res)
	fmt.Println(string(body))
}
