const express = require("express");
const app = express();
const port = 3000;
const products = require("./routes/products");


app.listen(port, err => {
	if(err){
		return console.log("ERROR", err);
	}
	console.log("Listening on port " + port)
});

app.use("/api/products", products);