.TL
plan for proof of concept

.NH
create a image deployer for the pi's

.NH 2
rewrite old script
.NH 2
update binary grab
.NH 2
change apt deps

.NH
rewrite summer project in go
.PP
will not need to duplicate any of the influxdb stuff as moving to prometheus.

.NH 2
rewrite client in go

.NH 2
rewrite the backend
.PP
rewrite in go and later package into snap for deployment from the ubuntu core image

.NH
rewrite the webui to handle the new backend

.NH 2
completely update UI
.PP
ui for the summer project was lackluster and poor. potentially keep the cubism.js stuff but parralell coordinates is horrendously documented.
look into serving some kind of static pages with the use of hugo on gitlab.
will also need to look having a static data source for demonstration purposes ( of the website )

.NH
deploy code into snaps

.NH
change image deployer into a ubuntu core image
.PP
should have a number of advantages from this from better security to easy OTA updates. this was a major issue in the summer project and leaveraging snaps will eliminate this.
.NH
make any WiFi networks WPA2-E if possible
