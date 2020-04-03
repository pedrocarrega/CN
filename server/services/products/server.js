const app = require('koa')();
const router = require('koa-router')();
const table_name = "cn_table";

//inicio de utilizacao do dynamo

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
    FilterExpression: "#cc <> :empty_code", //not sure, nao quero strings vazias
    ExpressionAttributeNames: {
      "#cc": "category_code"
    },
    ExpressionAttributeValues: {
      ":empty_code" : {S: "-"},
      ":v" : {N: "0"}
    }
    /*Falta ainda selecionar os valores distinct
    Uma solucao seria fazer aqui a selecao de distinct values, 
    mas era melhor ver se a bd tem capacidade para o fazer*/
  }

  var results = [];

  function queryCategories(params, _callback){
    docClient.query (params, function scanUntilDone(err, data) {
   
    if (err) {
      //idk? What should we do in case of an error?
    }
    else {
      if(data.LastEvaluatedKey){
        params.ExclusiveStartKey = data.LastEvaluatedKey;
        results = results.concat(data.Items.map(item => item.category_code.S));
        //docClient.query(params, scanUntilDone); // does this work? I want to join the results recursively
        queryCategories(params,_callback);
      }else{
        //means all the results are queried
        results = results.concat(data.Items.map(item => item.category_code.S));
        _callback(results);
      }
    }
    })
  }

	//To be tested
  queryCategories(params, function(results){
    this.body = [...new Set(results))];
  });
  //var non_null = db.entries.filter((evt) => evt.category_code);
  
});

/**
 * Lists all brands in the dataset by popularity within all possible event types (view, cart and purchase)
 *
 * returns List
 **/
router.get('/api/products/popularBrands', function *(next) {

  var params = {
    TableName: table_name,
    KeyConditionExpression: "pk_id = :v",
    ProjectionExpression: "brand",
    FilterExpression: "#b != :empty_code", //not sure, nao quero strings vazias
    ExpressionAttributeNames: {
      "#b": "brand",
    },
    ExpressionAttributeValues: {
      ":empty_code" : {S: "-"},
      ":v" : {N: "0"}
    }
  }

  var results = [];

  function queryPopular(params, _callback){
    docClient.query (params, function (err, data) {
      if (err) {
        //idk? What should we do in case of an error?
      }
      else {
          if(data.LastEvaluatedKey){
            params.ExclusiveStartKey = data.LastEvaluatedKey;
            results = results.concat(data.Items.map(item => item.brand.S));
            //docClient.query(params, scanUntilDone); // does this work? I want to join the results recursively
            queryPopular(params,_callback);
          }else{
            //means all the results are queried
            results = results.concat(data.Items.map(item => item.brand.S));
            _callback(results);
          }
      }
    });
  }

  queryPopular(params, function(results){
    var sales = results;
    this.body = foo(sales);

    function foo(arr) {
      var prev;
      var conjunto = [];
        
        arr.sort();
        for ( var i = 0; i < arr.length; i++ ) {
            if ( arr[i] !== prev ) {
              conjunto.push({'brand': arr[i].S, 'popularity': 1, "sales": 0});
            } else {
              conjunto[conjunto.length-1].popularity++;
            }
            prev = arr[i];
        }
        return conjunto;
    }
  });  
});



/** TESTED AND WORKS
 * Gets the average sale price of a brand
 *
 * brand String Brand name
 * returns List
 **/
router.get('/api/products/salePrice/:brand', function *(next) {

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
        ":b_name": brand,//aqui é que se dá filter à brand que vem como param?
        ":evt_t": {S: "purchase"},
        ":v": {N: "0"}
    }    
  }

  var average = 0;
  var results = [];

  function querySalePrice(params, _callback){
    docClient.query (params, function (err, data) {
      if (err) {
        //idk? What should we do in case of an error?
      } else {
        if(data.LastEvaluatedKey){
          params.ExclusiveStartKey = data.LastEvaluatedKey;
          results = results.concat(data.Items.map(item => Number(item.price.N)));
          querySalePrice(params, _callback)
        }else{
          //means all the results are queried
          results = results.concat(data.Items.map(item => Number(item.price.N)));
          _callback(results);
        }
      }
    }); 
  }

  querySalePrice(params, function(results){
    var prices = results;
    var sum = 0;
    for(var i = 0; i < prices.length; i++){
      sum += prices[i];//MAROSCA
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
router.get('/api/products/salesByBrand', function *(next) {

  var params = {
    TableName: table_name,
    KeyConditionExpression: "pk_id = :v",
    ProjectionExpression: "brand",
    FilterExpression: "#et = :evt_t and #b != :b", //posso fazer isto?
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

  doQuery(params,function(results){
    this.body = foo(results);
  });

  function foo(arr) {
    var prev;
    var conjunto = [];
      
      arr.sort();
      for ( var i = 0; i < arr.length; i++ ) {
          if ( arr[i] !== prev ) {
            conjunto.push({'brand': arr[i], 'popularity': 0, "sales": 1});
          } else {
            conjunto[conjunto.length-1].sales++;
          }
          prev = arr[i];
      }
      return conjunto;
  }

    function doQuery(params, _callback) {
        docClient.query(params, function (err, data) {
            if (err) {
                //idk? What should we do in case of an error?
            } else {
                if (data.LastEvaluatedKey) {
                    params.ExclusiveStartKey = data.LastEvaluatedKey;
                    results = results.concat(data.Items.map(item => item.brand.S));
                    querySalePrice(params, _callback)
                } else {
                    //means all the results are queried
                    results = results.concat(data.Items.map(item => item.brand.S));
                    _callback(results);
                }
            }
        });
    }
});

app.use(router.routes());
app.use(router.allowedMethods());

app.listen(3000);

console.log('Worker started');