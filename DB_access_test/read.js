var AWS = require("aws-sdk");
//Mudar os credenciais aqui
let awsConfig = {
    "region": "eu-west-1",
    "endpoint": "http://dynamodb.eu-west-1.amazonaws.com",
    "accessKeyId": "AKIA6JR7LR5SWXKD73DH", 
    "secretAccessKey": "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"
};

AWS.config.update(awsConfig);
let docClient = new AWS.DynamoDB;

//Mudem a TableName nos params para o nome da vossa tabela
let fetchOneByKey = function () {
    
    //Exemplo de query, queries são realizadas obrigatoriamente por 1 PK
    /*
    var params = {
        TableName : "DBTest",
        KeyConditionExpression: "event_id = :v",
        ExpressionAttributeValues: {
            ":v": {N: '7'}
        }
    };

    docClient.query (params, function (err, data) {
        if (err) {
            console.log("users::fetchOneByKey::error - " + JSON.stringify(err, null, 2));
        }
        else {
            console.log("users::fetchOneByKey::success - " + JSON.stringify(data, null, 2));
        }
    })*/
    
    //Exemplo de scan, faz-se a filtragem de acordo com os parâmetros, têm operadores >, < etc caso queiram meter numeros na query
    /*
    var params = {
        TableName: "DBTest",
        FilterExpression: "#b = :b_name",
        ExpressionAttributeNames: {
            "#b": "brand",
        },
        ExpressionAttributeValues: { 
            ":b_name": {S: 'bq'}
        }
    }

    docClient.scan (params, function (err, data) {
        if (err) {
            console.log("users::fetchOneByKey::error - " + JSON.stringify(err, null, 2));
        }
        else {
            console.log("users::fetchOneByKey::success - " + JSON.stringify(data, null, 2));
            /*
            count=0;
            data.Items.forEach(function(itemdata) {
                console.log("Item :", ++count,JSON.stringify(itemdata));
             });
            *
        }
    })*/
var brand = "apple";

  var params = {
    TableName: "cn_table",
    KeyConditionExpression: "pk_id = :v",
    ProjectionExpression: "price",
    FilterExpression: "#b = :b_name and #t = :evt_t",
    ExpressionAttributeNames: {
        "#b": "brand",
        "#t": "event_type"
    },
    ExpressionAttributeValues: { 
        ":b_name": {S: brand},//aqui é que se dá filter à brand que vem como param?
        ":evt_t": {S: "purchase"},
        ":v": {N: "0"}
    }    
  }

  var average = 0;
  var results = [];
	var total= 0;

  function querySalePrice(params, _callback){
    docClient.query (params, function (err, data) {
      if (err) {
        //idk? What should we do in case of an error?
        console.log(err);
        for (var key in params) { console.log(key); }
      } else {
        if(data.LastEvaluatedKey){
          params.ExclusiveStartKey = data.LastEvaluatedKey;
          results = results.concat(data.Items);
total += data.Items.length;
          console.log("total :" + (data.Items.map(item => Number(item.price.N))[0]-10000));
          querySalePrice(params, _callback)
        }else{
          //means all the results are queried
          results = results.concat(data.Items);
          _callback(results);
        }
      }
    }); 
  }

  querySalePrice(params, function(results){
    var prices = results;
    var sum = 0;
    for(var i = 0; i < prices.length; i++){
      //sum += Number(prices[i].price.N);
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
    };
    console.log(this.body);
  });
      //var non_null = db.entries.filter((evt) => evt.category_code);
      

}
fetchOneByKey();
        