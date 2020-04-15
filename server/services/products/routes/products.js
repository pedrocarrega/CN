const mongo = require('mongodb').MongoClient;
const express = require("express");
let router = express.Router();
const url = "mongodb+srv://sprint1:sprint1@cn-db-cfmpq.mongodb.net/test?retryWrites=true&w=majority";

//var AWS = require("aws-sdk");
//const table_name = "cn_table"


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
        res.send("Products service available: \n - /api/products/ \n")
    });

router
    .route("/listCategories")
    .get((req, res) => {

        mongo.connect(url, function (err, db){

            if (err) throw err;
            var dbo = db.db("mongodb");

            var results = await dbo.collection("entries").distinct("category_code");
            console.log(results);

            res.write(JSON.stringify(results));
            res.end();
            //var counter = 0;

            /*var params = {
                TableName: table_name,
                KeyConditionExpression: "pk_id = :v",
                ProjectionExpression: "category_code",
                FilterExpression: "#cc <> :empty_code",
                ExpressionAttributeNames: {
                  "#cc": "category_code"
                },
                ExpressionAttributeValues: {
                  ":empty_code" : {S: "-"},
                  ":v" : {N: "0"}
                }
            }
            
            
            
            
            function queryCategories(params, _callback){
            docClient.query (params, function queryUntilDone(err, data) {
            
                if (err) {
                    console.log("listCategories Err");
                    console.log(err);
                }
                else {
                    if(data.LastEvaluatedKey){
                        params.ExclusiveStartKey = data.LastEvaluatedKey;
                        results = results.concat(data.Items.map(item => item.category_code.S));
                        counter += data.Items.length;
                        res.write(counter + " entradas validas\n");
                        queryCategories(params,_callback);
                    }else{
                        results = results.concat(data.Items.map(item => item.category_code.S));
                        counter += data.Items.length;
                        console.log("terminou:" + counter);
                        _callback(results);
                    }
                }
                });
            }
            */



            queryCategories(params, function (results) {
                res.write(JSON.stringify([...new Set(results)]));
                res.end();
            });
        });
    });


router
    .route("/popularBrands")
    .get((req, res) => {

        mongo.connect(url, function (err, db) {

            if (err) throw err;
            var dbo = db.db("mongodb");

            var query = await dbo.collection("entries").find().sort(brand);
            let results = [];

            for (var i = 0; i < query.length; i++) {
                results.push({ query.brand, dbo.collection("entries").count({ brand: query.brand }) });
            }

            //handleBrands(query);

            res.write(JSON.stringify(results));
            res.end();

        });

        /*
        var params = {
            TableName: table_name,
            KeyConditionExpression: "pk_id = :v",
            ProjectionExpression: "brand",
            FilterExpression: "#b <> :empty_code", //not sure, nao quero strings vazias
            ExpressionAttributeNames: {
                "#b": "brand",
            },
            ExpressionAttributeValues: {
                ":empty_code" : {S: "-"},
                ":v" : {N: "0"}
            }
        }
        
        var counter = 0;
        var results = {};
    
        function queryPopular(params, _callback){
            docClient.query (params, function (err, data) {
                if (err) {
                console.log("popularBrands Err");
                console.log(err);
                }
                else {
                    if(data.LastEvaluatedKey){
                    params.ExclusiveStartKey = data.LastEvaluatedKey;
                    counter += data.Items.length;
                    res.write(counter + " entradas validas\n");
                    handleBrands(results, data.Items,function(){
                        queryPopular(params,_callback);
                    });
                    
                    }else{
                    handleBrands(results, data.Items, function(){
                        counter += data.Items.length;
                        _callback(results);
                    });
                    
                    }
                }
            });
        }
        
        queryPopular(params, function(results){
            res.write(JSON.stringify(results));
            res.end();
        }); 
        */
    });

router
    .route("/salePrice/:brand")
    .get((req, res) => {
        console.log("got request");

        var brand = req.params.brand;
        console.log(brand);

        mongo.connect(url, function (err, db) {
            if (err) throw err;
            var dbo = db.db("mongodb");

            var results = await dbo.collection("entries").find({ brand: brand, event_type : 'purchase' });
            var result = results.reduce((Number(a.price), Number(b.price)) => a + b, 0);

            res.write(JSON.stringify(result));
            res.end();
        });

        /*
        var params = {
            TableName: table_name,
            ProjectionExpression: "price",
            KeyConditionExpression: "pk_id = :v",
            FilterExpression: "#b = :b_name and #t = :evt_t",
            ExpressionAttributeNames: {
                "#b": "brand",
                "#t": "event_type"
            },
            ExpressionAttributeValues: { 
                ":b_name": {S: brand},
                ":evt_t": {S: "purchase"},
                ":v": {N: "0"}
            }    
        }

        var average = 0;
        var results = [];
        var counter = 0;

        function querySalePrice(params, _callback){
            docClient.query (params, function (err, data) {
                if (err) {
                    console.log("salePrice Err");
                    console.log(err);
                } else {
                    if(data.LastEvaluatedKey){
                    params.ExclusiveStartKey = data.LastEvaluatedKey;
                    results = results.concat(data.Items.map(item => Number(item.price.N)));
                    querySalePrice(params, _callback)
                    counter += data.Items.length;
                    res.write(counter + " entradas validas\n");
                    }else{
                    //means all the results are queried
                    results = results.concat(data.Items.map(item => Number(item.price.N)));
                    counter += data.Items.length;
                    console.log("terminated " + counter);
                    _callback(results);
                    }
                }
            }); 
        }

        querySalePrice(params, function(results){
            var prices = results;
            var sum = 0;
            for(var i = 0; i < prices.length; i++){
            sum += prices[i];
            }
            average = sum/prices.length;

            var response = {
                "brand": {
                    "brandName": brand,
                    "popularity": 0,
                    "sales": prices.length
                },
                "price": average,
                "category": {
                    "name": ""
                }
            }
            res.write(JSON.stringify(response));
            res.end();
        });
        */
    });

router
    .route('/salesByBrand')
    .get((req, res) => {

        mongo.connect(url, function (err, db) {
            if (err) throw err;

            var dbo = db.db("mongodb");

            //var query = dbo.collection("entries").find({ event_type: 'purchase' }).sort(brand);

            var query = dbo.collection("entries").distinct({ event_type: 'purchase' });

            let results = [];

            for (var i = 0; i < query.length; i++) {
                results.push({ query.brand, dbo.collection("entries").count({ brand: query.brand }) });
            }

            //handleBrands(query);
            res.send(JSON.stringify(results));
            res.end();
        });

        /*
        var params = {
            TableName: table_name,
            KeyConditionExpression: "pk_id = :v",
            ProjectionExpression: "brand",
            FilterExpression: "#et = :evt_t and #b <> :b", //posso fazer isto?
            ExpressionAttributeNames: {
                "#et": "event_type",
                "#b": "brand"
            },
            ExpressionAttributeValues: { 
                ":evt_t": { S: 'purchase' }, //é assim que filtro so vendas?
                ":b": {"S": '-'},
                ":v": {"N": '0'}
            }    
        }

        var counter = 0;
        var results = {};
        
        function doQuery(params, _callback) {
            docClient.query(params, function (err, data) {
                if (err) {
                    console.log("salesByBrand Err");
                    console.log(err);
                } else {
                    if (data.LastEvaluatedKey) {
                        params.ExclusiveStartKey = data.LastEvaluatedKey;
                        handleBrands(results, data.Items, function(){
                            counter += data.Items.length;
                            res.write(counter + " entradas validas\n");
                            doQuery(params, _callback);
                        });
                    } else {
                        handleBrands(results, data.Items, function(){
                            counter += data.Items.length;
                            _callback(results);
                        });
                    }
                }
            });
        }

        doQuery(params,function(results){
            res.write(JSON.stringify(results));
            res.end();
        });
        */
    });

function handleBrands(data, _callback){
    var brand_name;
    for(var i = 0; i < data.length; i++){
        brand_name = data[i].brand;
        if(results[brand_name]){
            results[brand_name] += 1;
        }else{
            results[brand_name] = 1;
        }
    }
    _callback();
}