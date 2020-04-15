const express = require("express");
let router = express.Router();
const mongo = require('mongodb').MongoClient;
const url = "mongodb://database:27017";

module.exports = router;

router
    .route("/")
    .get((req, res) => {
        res.send("Events service available: \n - /api/events/ratio \n")
    });

router
    .route("/ratio")
    .get((req, res) => {
        var events = {};

        mongo.connect(url, async function (err, db) {
            if (err) throw err;
            var dbo = db.db("ecommerce");

            var cursor = dbo.collection("entries").aggregate([{$group: {_id: '$event_type', count: {$sum: 1}}}])
            var result = {"results": []};

            cursor.each(function(err, docs) {
                
                
                if(docs == null) {
                    db.close();
                  
                    const total = events.view + events.cart + events.purchase;

                    const ratios = [events.view / total, events.cart / total, events.purchase / total]
                    console.log("Ended with: " + total + " values.")
                    console.log(ratios)
                    result.results.push([
                        {
                            "eventType": "view",
                            "eventTime": "",
                            "ratio": ratios[0],
                            "count": events.view
                        },
                        {
                            "eventType": "cart",
                            "eventTime": "",
                            "ratio": ratios[1],
                            "count": events.cart
                        },
                        {
                            "eventType": "purchase",
                            "eventTime": "",
                            "ratio": ratios[2],
                            "count": events.purchase
                        }
                    ]);
                    console.log(result);
                    res.send(result);
                }else{
                    events[docs._id] = docs.count;
                }
            });
        });
    });