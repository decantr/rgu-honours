package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
)

func main() {

	turl := "http://localhost:8086/write?db=test"

	res, err := http.PostForm(turl,
		url.Values{"measurement": {"usage"}})

	//  "tags": url.Values{"host": \"xps"}, "fields": url.Values{"cpu_usage": "100"}})

	//	res, err := http.PostForm("http://duckduckgo.com",
	//		url.Values{"q": {"github"}})

	if err != nil {
		log.Fatal(err)
	}

	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	fmt.Println("p:\n", string(body), 3)
	fmt.Println("response Status:", res.Status)
	fmt.Println("response Headers:", res.Header)
}
