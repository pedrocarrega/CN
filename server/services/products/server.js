const app = require('koa')();
const router = require('koa-router')();
const table_name = "cn_table";

//inicio de utilizacao do dynamo
var fs = require('fs');
var util = require('util');
var log_file = fs.createWriteStream(__dirname + '/debug.log', {flags : 'w'});
var log_stdout = process.stdout;

console.log = function(d) { //
  log_file.write(util.format(d) + '\n');
  log_stdout.write(util.format(d) + '\n');
};

var AWS = require("aws-sdk");
//Mudar os credenciais aqui
let awsConfig = {
    "region": "eu-west-1",
    "endpoint": "http://dynamodb.eu-west-1.amazonaws.com",
    "accessKeyId": "AKIA6JR7LR5S5FC3PG4D", 
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

/**
 * Lists all product categories made available in the dataset
 *
 * returns List
 **/

router.get('/api/products/listCategories', function *(next) {

  var params = {
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

  var results = [];
  var counter = 0;

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
        couter += data.Items.length;
        console.log(counter);
        queryCategories(params,_callback);
      }else{
        results = results.concat(data.Items.map(item => item.category_code.S));
        couter += data.Items.length;
        console.log("terminou:" + counter);
        _callback(results);
      }
    }
    })
  }
  queryCategories(params, function(results){
    this.body = [...new Set(results)];
  });
  
});

/**
 * Lists all brands in the dataset by popularity within all possible event types (view, cart and purchase)
 *
 * returns List
 **/
router.get('/api/products/popularBrands', function *() {

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
            console.log(counter);
            handleBrands(results, data.Items,function(){
              queryPopular(params,_callback);
            });
            
          }else{
            handleBrands(results, data.Items, function(){
              couter += data.Items.length;
              console.log("terminou:" + counter);
              _callback(results);
            });
            
          }
      }
    });
  }

  function handleBrands(popularity, data, _callback){
    var brand_name;
    for(var i = 0; i < data.Items.length; i++){
      brand_name = data.Items[i].brand.S;
      if(popularity[brand_name]){
        popularity[brand_name] += 1;
      }else{
        popularity[brand_name] = 1;
      }
    }
    _callback();
  }

  queryPopular(params, function(results){
    this.body = results;
  });  
});



/** TESTED AND WORKS
 * Gets the average sale price of a brand
 *
 * brand String Brand name
 * returns List
 **/
router.get('/api/products/salePrice/:brand', function *() {

  console.log("got request");

  var brand = this.params.brand;

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
          console.log(data.Items);
          console.log("another page " + counter);
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

    this.body = {
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
  })
});

/**
 * Lists number of sales made by each brand
 *
 * returns List
 **/
router.get('/api/products/salesByBrand', function *() {

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

  var results = [];
  var counter = 0;

  doQuery(params,function(results){
    this.body = results;
  });

  function handleBrands(popularity, data, _callback){
    var brand_name;
    for(var i = 0; i < data.Items.length; i++){
      brand_name = data.Items[i].brand.S;
      if(popularity[brand_name]){
        popularity[brand_name] += 1;
      }else{
        popularity[brand_name] = 1;
      }
    }
    _callback();
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
                      console.log(counter);
                      querySalePrice(params, _callback);
                    });
                } else {
                    handleBrands(results, data.Items, function(){
                      counter += data.Items.length;
                      console.log(counter);
                      _callback(results);
                    });
                }
            }
        });
    }
});

app.use(router.routes());
app.use(router.allowedMethods());

app.listen(3000);

console.log('Worker started');