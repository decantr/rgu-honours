const val = document.getElementById('time-increments')

val.addEventListener('change', () => {
	build(val.value)
}, false)

function build(time) {
	d3.select(document.getElementById('para')).selectAll("*").remove()

	const color = (d) => {
		return d3.scale
			.linear()
			.domain([9, 50])
			.range(["steelblue", "brown"])
			.interpolate(d3.interpolateLab)(d['time'])
	}

	const parcoords = d3
		.parcoords()('#para')
		.color(color)

	d3.json('http://pinas:3000/data?type=mean&time=' + time, (data) => {
		console.log(data)
		parcoords
			.data(data)
			.hideAxis(["time", "host"])
			.composite("darker")
			.render()
			.shadows()
			.reorderable()
			.brushMode("1D-axes")
	})
}
