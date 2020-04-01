const app = require('koa')();
const router = require('koa-router')();
const db = require('./db.json');

var AWS = require("aws-sdk");
var fs = require("fs");
let awsConfig = {
	"region": "us-east-1",
	"endpoint": "http://dynamodb.us-east-1.amazonaws.com",
	"accessKeyId": "AKIA3IUB2LYWHZQT3PXJ",
	"secretAccessKey": "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"
};

AWS.config.update(awsConfig);
let docClient = new AWS.DynamoDB;

// Log requests
app.use(function *(next){
  const start = new Date;
  yield next;
  const ms = new Date - start;
  console.log('%s %s - %s', this.method, this.url, ms);
});

router.get('/api/events/ratio', function* (next) {

	var result = [0, 0, 0];

	result[0] = function (callback) {

		const qParams = {
			TableName: "cn_database",
			KeyConditionExpression: "event_type = :event",
			ExpressionAttributeValues: {
				":event": { "S": "view" },
			}
		}
		callback(doQueryCount(qParams, 0));
	}

	result[1] = function (callback) {

		const qParams = {
			TableName: "cn_database",
			KeyConditionExpression: "event_type = :event",
			ExpressionAttributeValues: {
				":event": { "S": "purchase" },
			}
		}
		callback(doQueryCount(qParams, 0));
	}

	result[2] = function (callback) {

		const qParams = {
			TableName: "cn_database",
			KeyConditionExpression: "event_type = :event",
			ExpressionAttributeValues: {
				":event": { "S": "cart" },
			}
		}
		callback(doQueryCount(qParams, 0));
	}


	/*
	var total = 0;
	for(var i = 0; i < vals.length; i++) {
		if(vals[i] == "view"){
			count[0]++;
		}else if(vals[i] == "cart"){
			count[1]++;
		}else if(vals[i] == "purchase"){
			count[2]++;
		}
		total++;
	}
	*/

	const ratios = [result[0]/total, result[1]/total, result[2]/total];
	console.log(ratios);
	this.body = [
		{
		  "eventType": "view",
			"eventTime": "",
			"ratio": ratios[0],
			"count": result[0]
		},
		{
			"eventType": "cart",
			"eventTime": "",
			"ratio": ratios[1],
			"count": result[1]
		},
		{
			"eventType": "purchase",
			"eventTime": "",
			"ratio": ratios[2],
			"count": result[2]
		}
	];
});

app.use(router.routes());
app.use(router.allowedMethods());

app.listen(3000);

console.log('Worker started');

function doQueryCount(qParams, count, callback) {

	docClient.query(qParams, function (err, data) {
		if (err) {
			console.log("users::fetchOneByKey::error - " + JSON.stringify(err, null, 2));
		}
		else {
			// console.log("users::fetchOneByKey::success - " + JSON.stringify(data, null, 2));
			console.log("Success");
			if (!data.hasOwnProperty('LastEvaluatedKey')) {
				count += data.Count;
				console.log("Acabou com: " + count + " entradas.");
				callback(count);
			} else {
				count += data.Count;
				console.log("Passou para o next " + count);
				params.ExclusiveStartKey = data.LastEvaluatedKey;
				doQueryCount(params, count, callback);
			}
		}
	})
}