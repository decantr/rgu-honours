package main

import (
	"fmt"
	"net/http"
	"bytes"
)

func main() {

	url := "http://localhost:8086"

	var jpacket = []byte(`[{
            'measurement': 'test',
            'tags': {
                "host": xps
            },
            'fields': {
                'cpu_usage': 100
            }
        }]`)

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jpacket))

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)

	if err != nil {
		panic(err)
	}

	defer resp.Body.Close()
	fmt.Println("response Status:", resp.Status)
	fmt.Println("response Headers:", resp.Header)
}
