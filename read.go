package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"time"
)

func main() {

	client := http.Client{}
	turl := "http://localhost:8086/write?db=test&"
	name, _ := os.Hostname()

	rand.Seed(time.Now().UnixNano())

// simulated water level, temperature, purity and current
	lvl := strconv.Itoa(rand.Intn(12))
	tmp := strconv.Itoa(rand.Intn(30))
	pry := strconv.Itoa(rand.Intn(100))
	crn := strconv.Itoa(rand.Intn(30))

	var jstrs string = "usage,host=" + name + " water_level=" + lvl + ",water_temp=" + tmp + ",water_purity=" + pry + ",water_current=" + crn
	var jstr = []byte(jstrs)

	req, _ := http.NewRequest("POST", turl, bytes.NewBuffer(jstr))
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
