const express = require("express");
const app = express();
const port = 3000;
const events = require("./routes/events")


app.listen(port, err => {
	if(err){
		return console.log("ERROR", err);
	}
	console.log("Listening on port " + port)
});

app.use("/api/events", events)