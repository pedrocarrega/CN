const mongo = require('mongodb').MongoClient;
const express = require("express");
let router = express.Router();
const url = "mongodb://database:27017";

module.exports = router;

router
    .route("/")
    .get((req, res) => {
        res.send("Products service available: \n - /api/products/ \n")
    });

router
    .route("/listCategories")
    .get((req, res) => {

        mongo.connect(url, async function (err, db){

            if (err) throw err;
            var dbo = db.db("ecommerce");

            var results = await dbo.collection("entries").distinct("category_code");
            var result = {"results":[]};
            for(var i = 0; i < results.length; i++){
                result.results.push({"name": results[i]})
            }

            res.send(result);            
        });
    });


router
    .route("/popularBrands")
    .get((req, res) => {

        mongo.connect(url, async function (err, db) {

            if (err) throw err;
            var dbo = db.db("ecommerce");
            
            var cursor = dbo.collection("entries").aggregate([{$group: {_id: '$brand', count: {$sum: 1}}}])
            var result = {"results": []};

            cursor.each(function(err, docs) {
                
                
                if(docs == null) {
                  db.close();
                  res.send(result);
                  console.log(result);
                }else{
                    result.results.push({"brandName": docs._id, "popularity":docs.count, "sales": 0});
                }
            });
        });
    });

router
    .route("/salePrice/:brand")
    .get((req, res) => {

        var brand = req.params.brand;

        mongo.connect(url, async function (err, db) {
            if (err) throw err;
            var dbo = db.db("ecommerce");
            var result = 0;
            var count = 0;
            var result = {"results": []};
            
            var cursor = dbo.collection("entries").aggregate([{ "$match": { "brand": brand}},{$group: {_id: '$brand', total: {$sum: 1}, sum: {$sum: '$price'}}}])//.forEach(printjson);
            cursor.each(function(err, docs) {
                
                
                if(docs == null) {
                    db.close();
                    res.send(result);
                    console.log(result);
                }else{
                    result.results.push({"brand":{"brandName":docs._id,"popularity":0, "sales":0},"price":docs.sum/docs.total, "category":{"name": ""}});
                }
            });  
        });  
    });

router
    .route('/salesByBrand')
    .get((req, res) => {

        mongo.connect(url, async function (err, db) {

            if (err) throw err;
            var dbo = db.db("ecommerce");
            
            var cursor = dbo.collection("entries").aggregate([{ "$match": { "event_type": "purchase"}},{$group: {_id: '$brand', count: {$sum: 1}}}])//.forEach(printjson);

            var result = {"results": []};
            cursor.each(function(err, docs) {
                
                
                if(docs == null) {
                    db.close();
                    res.send(result);
                    console.log(result);
                }else{
                    result.results.push({"brandName": docs._id, "popularity":0, "sales": docs.count});
                }
            });    
            
        });
    });