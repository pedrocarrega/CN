const express = require("express");
let router = express.Router();
//var AWS = require("aws-sdk");
//const table_name = "cn_table"
const mongo = require('mongodb').MongoClient;
const url = "mongodb+srv://sprint1:sprint1@cn-db-cfmpq.mongodb.net/test?retryWrites=true&w=majority";

/*
let awsConfig = {
	"region": "eu-west-1",
	"endpoint": "http://dynamodb.eu-west-1.amazonaws.com",
	"accessKeyId": "AKIA6JR7LR5S5FC3PG4D",
	"secretAccessKey": "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"
};

AWS.config.update(awsConfig);
let docClient = new AWS.DynamoDB;
*/
module.exports = router;

router
    .route("/")
    .get((req, res) => {
        res.send("Events service available: \n - /api/events/ratio \n")
    });
/*
router
    .route("/test")
    .get((req, res) => {
        var params = {
            TableName : table_name,
            ProjectionExpression: "event_type",
            KeyConditionExpression: "pk_id = :v and event_id < :e",
            ExpressionAttributeValues: {
                ":v": {N: '0'},
                ":e": {N: '20000'}
            }
        };

        test2(params,0,function(result){
            var result = {"result": result}
            res.send(result)
        });
    });
*/

router
    .route("/ratio")
    .get((req, res) => {
        console.log("test");
        var events = [0, 0, 0];

        mongo.connect(url, async function (err, db) {
            if (err) throw err;
            var dbo = db.db("ecommerce");

            events[0] = await dbo.collection("entries").countDocuments({ event_type: 'view' });
            events[1] = await dbo.collection("entries").countDocuments({ event_type: 'cart' });
            events[2] = await dbo.collection("entries").countDocuments({ event_type: 'purchase' });

            const total = events[0] + events[1] + events[2];

            const ratios = [events[0] / total, events[1] / total, events[2] / total]
            console.log("Ended with: " + total + " values.")
            console.log(ratios)
            var result = [
                {
                    "eventType": "view",
                    "eventTime": "",
                    "ratio": ratios[0],
                    "count": events[0]
                },
                {
                    "eventType": "cart",
                    "eventTime": "",
                    "ratio": ratios[1],
                    "count": events[1]
                },
                {
                    "eventType": "purchase",
                    "eventTime": "",
                    "ratio": ratios[2],
                    "count": events[2]
                }
            ];
            console.log(result)
            res.write(JSON.stringify(result));
            res.end();
        });

        /*
        var params = {
            TableName : table_name,
            ProjectionExpression: "event_type",
            KeyConditionExpression: "pk_id = :v",
            ExpressionAttributeValues: {
                ":v": {N: '0'}
            }
        };

        

        doQueryCount(params, events, 0, res, function(total, result){

            const ratios = [result[0]/total, result[1]/total, result[2]/total]
            console.log("Ended with: " + total + " values.")
            console.log(ratios)
            var result =[
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
            console.log(result)
            res.write(JSON.stringify(result));
            res.end();
        });
        */
    });
/*
function test2(params,count,_callback){
    docClient.query (params, function (err, data) {
        if (err) {
            console.log("users::fetchOneByKey::error - " + JSON.stringify(err, null, 2));
        }
        else {
            if (!data.hasOwnProperty('LastEvaluatedKey')) {
                count += data.Count;
                _callback(count);
            }else{
                count += data.Count;
                console.log("Passou para o next " + count);
                params.ExclusiveStartKey = data.LastEvaluatedKey;
                test2(params,count,_callback);
            }
        }
    })
}

function doQueryCount(qParams, events, count, res, callback) {

	docClient.query(qParams, function (err, data) {
		if (err) {
			console.log("users::fetchOneByKey::error - " + JSON.stringify(err, null, 2));
		}
		else {
			// console.log("users::fetchOneByKey::success - " + JSON.stringify(data, null, 2));
			if (!data.hasOwnProperty('LastEvaluatedKey')) {
                count += data.Count;
                for(i = 0; i < data.Items.length; i++){
					if(data.Items[i].event_type.S == 'view'){
						events[0]++
					}else if(data.Items[i].event_type.S == 'cart'){
						events[1]++
					}else if(data.Items[i].event_type.S == 'purchase'){
						events[2]++
                    }
                }
                var ratios = [events[0]/count, events[1]/count, events[2]/count]
                var result =[
                    {
                        "eventType": "view",
                        "eventTime": "",
                        "ratio": ratios[0],
                        "count": events[0]
                    },
                    {
                        "eventType": "cart",
                        "eventTime": "",
                        "ratio": ratios[1],
                        "count": events[1]
                    },
                    {
                        "eventType": "purchase",
                        "eventTime": "",
                        "ratio": ratios[2],
                        "count": events[2]
                    }
                ];
                res.write(JSON.stringify(result)+"\n");
				callback(count,events);
			} else {
				count += data.Count;
				for(i = 0; i < data.Items.length; i++){
					if(data.Items[i].event_type.S == 'view'){
						events[0]++
					}else if(data.Items[i].event_type.S == 'cart'){
						events[1]++
					}else if(data.Items[i].event_type.S == 'purchase'){
						events[2]++
					}
                }

                var ratios = [events[0]/count, events[1]/count, events[2]/count]
                var result =[
                    {
                        "eventType": "view",
                        "eventTime": "",
                        "ratio": ratios[0],
                        "count": events[0]
                    },
                    {
                        "eventType": "cart",
                        "eventTime": "",
                        "ratio": ratios[1],
                        "count": events[1]
                    },
                    {
                        "eventType": "purchase",
                        "eventTime": "",
                        "ratio": ratios[2],
                        "count": events[2]
                    }
                ];
                res.write(JSON.stringify(result) + "\n");
				qParams.ExclusiveStartKey = data.LastEvaluatedKey;
				doQueryCount(qParams,events,count,res,callback);
			}
		}
	})
}
*/