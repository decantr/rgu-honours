package main

import (
	"bytes"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"time"
)

func main() {
	// create random seed from current time
	rand.Seed(time.Now().UnixNano())

	// create things for later
	const url = "http://sensor-bridge.local:8086/write?db=test&"
	cln := http.Client{}
	hst, _ := os.Hostname()

	// simulated water level, temperature, purity and current
	lvl := strconv.Itoa(rand.Intn(12))
	tmp := strconv.Itoa(rand.Intn(30))
	pry := strconv.Itoa(rand.Intn(100))
	crn := strconv.Itoa(rand.Intn(30))

	// construct the string to send to influx and convert to bytestream
	jss := "usage,host=" + hst + " water_level=" + lvl + ",water_temp=" + tmp + ",water_purity=" + pry + ",water_current=" + crn
	jsb := []byte(jss)

	// create the post request and set the content type
	req, _ := http.NewRequest("POST", url, bytes.NewBuffer(jsb))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	// attach the request to the client and send
	res, _ := cln.Do(req)
	res.Body.Close()
}
