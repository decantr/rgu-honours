const express = require('express')
const http = require('http');
const app = express()

//Allow all requests from all domains & localhost
app.all('/*', function (req, res, next) {
	res.header("Access-Control-Allow-Origin", "*")
	res.header("Access-Control-Allow-Headers", "X-Requested-With, Content-Type, Accept")
	res.header("Access-Control-Allow-Methods", "GET")
	next()
})

app.get('/data', (req, res) => {
	if (req.query.type == "mean") {

		const time = req.query.time ? req.query.time : '1h'

		http.request({
			host: 'localhost',
			port: '8086',
			path: '/query?&db=main&q=select%20mean%28%2A%29%20from%20usage%20where%20time%20%3E%20now%28%29%20-%20' + time + '%20group%20by%20host'
		}, (r) => {
			var str = ''
			r.on('data', (c) => {
				str += c;
			});

			r.on('end', () => {
				str = JSON.parse(str)
				str = str.results[0].series
				var d = []

				for (let i in str) {
					d[i] = {
						host: str[i].tags.host,
						water_current: +str[i].values[0][1],
						water_level: +str[i].values[0][2],
						water_purity: +str[i].values[0][3],
						water_temp: +str[i].values[0][4],
					}
				}

				res.send(d)
			});
		}).end();
	} else if ( req.query.type == "val") {
		const count = req.query.count ? req.query.count : 1

		http.request({
			host: 'localhost',
			port: '8086',
			path: '/query?&db=main&q=select%20%2A%20from%20usage%20group%20by%20host%20limit%20' + count
		}, (r) => {
			var str = ''
			r.on('data', (c) => {
				str += c;
			});

			r.on('end', () => {
				str = JSON.parse(str)
				str = str.results[0].series
				var d = []

				for (let i in str) {
					d[i] = []
					for ( let j in str[i].values ) {
						d[i][j] = {
							host: str[i].tags.host,
							water_current: +str[i].values[j][1],
							water_level: +str[i].values[j][2],
							water_purity: +str[i].values[j][3],
							water_temp: +str[i].values[j][4],
						}
					}
				}
				res.send(d)
			});
		}).end();
	}
})

app.listen(3000, (error) => {
	if (error) console.log(error)
})
