var AWS = require("aws-sdk");
//Mudar os credenciais aqui
let awsConfig = {
    "region": "us-east-1",
    "endpoint": "http://dynamodb.us-east-1.amazonaws.com",
    "accessKeyId": "ID", 
    "secretAccessKey": "SECRET_KEY"
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
            */
        }
    })

}

fetchOneByKey();
        