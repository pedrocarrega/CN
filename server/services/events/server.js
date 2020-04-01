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

	var events = [0, 0, 0];

	var params = {
	TableName : "cn_database",
	KeyConditionExpression: "pk_id = :v",
	ExpressionAttributeValues: {
	    ":v": {N: '0'}
	}
	};

	doQueryCount(params, events, 0, function(total, result){

		const ratios = [result[0]/total, result[1]/total, result[2]/total]
		console.log("Ended with: " + total + " values.")
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
	console.log(this.body);
	});
});

app.use(router.routes());
app.use(router.allowedMethods());

app.listen(3000);

console.log('Worker started');

function doQueryCount(qParams, events, count, callback) {

	docClient.query(qParams, function (err, data) {
		if (err) {
			console.log("users::fetchOneByKey::error - " + JSON.stringify(err, null, 2));
		}
		else {
			// console.log("users::fetchOneByKey::success - " + JSON.stringify(data, null, 2));
			console.log("Success");
			if (!data.hasOwnProperty('LastEvaluatedKey')) {
                count += data.Count;
                for(i = 0; i < data.Items.length; i++){
                    console.log(data.Items[i].event_type.S)
					if(data.Items[i].event_type.S == 'view'){
						events[0]++
					}else if(data.Items[i].event_type.S == 'cart'){
						events[1]++
					}else if(data.Items[i].event_type.S == 'purchase'){
						events[2]++
					}
				}
				callback(count,events);
			} else {
				count += data.Count;
                console.log("Passou para o next " + count);
				for(i = 0; i < data.Items[i].S; i++){
                    console.log(data.Items[i].event_type.S)
					if(data.Items[i].event_type.S == 'view'){
						events[0]++
					}else if(data.Items[i].event_type.S == 'cart'){
						events[1]++
					}else if(data.Items[i].event_type.S == 'purchase'){
						events[2]++
					}
				}
				params.ExclusiveStartKey = data.LastEvaluatedKey;
				doQueryCount(params,events,count,callback);
			}
		}
	})
}
