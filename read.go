package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

func main() {

	client := http.Client{}
	turl := "http://localhost:8086/write?db=test&"

	jstrs := "usage,host=xps cpu_usage=77"
	var jstr = []byte(jstrs)

	req, err := http.NewRequest("POST", turl, bytes.NewBuffer(jstr))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	res, err := client.Do(req)

	if err != nil {
		log.Fatal(err)
	}

	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	fmt.Println("response Status:", res.Status)
	fmt.Println("response Headers:", res.Header)
	fmt.Println("response Body:", string(body))
}
