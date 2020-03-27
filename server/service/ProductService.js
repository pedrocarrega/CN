'use strict';
const db = require('./db.json'); //to remove later


/**
 * Lists all product categories made available in the dataset
 *
 * returns List
 **/
exports.listCategories = function() {
  return new Promise(function(resolve, reject) {
    var examples = {};
    examples['application/json'] = [ {
  "name" : "name"
}, {
  "name" : "name"
} ];
    if (Object.keys(examples).length > 0) {
      resolve(examples[Object.keys(examples)[0]]);
    } else {
      resolve();
    }
  });
}


/**
 * Lists all brands in the dataset by popularity within all possible event types (view, cart and purchase)
 *
 * returns List
 **/
exports.mostPopularBrands = function() {
  return new Promise(function(resolve, reject) {
    var examples = {};
    examples['application/json'] = [ {
  "brandName" : "brandName",
  "popularity" : 0.8008281904610115,
  "sales" : 6.02745618307040320615897144307382404804229736328125
}, {
  "brandName" : "brandName",
  "popularity" : 0.8008281904610115,
  "sales" : 6.02745618307040320615897144307382404804229736328125
} ];
    if (Object.keys(examples).length > 0) {
      resolve(examples[Object.keys(examples)[0]]);
    } else {
      resolve();
    }
  });
}


/**
 * Gets the average sale price of a brand
 *
 * brand String Brand name
 * returns List
 **/
exports.salePrice = function(brand) {
  return new Promise(function(resolve, reject) {
    
    const entries = db.entries.filter((entries) => entries.brand == brand);
    
    if (Object.keys(entries).length > 0) {

      let result = [...new Set(entries.filter((object,index) => index === entries.findIndex(obj => JSON.stringify(obj.product_id) === JSON.stringify(object.product_id))).map(item => item.price))];

      resolve(Math.round(((result.reduce(function(total, num){
        return parseFloat(total) + parseFloat(num);
    })/result.length) + Number.EPSILON) * 100) / 100);
    } else {
      resolve(-1);
    }
  });
}


/**
 * Lists all sales made by each brand
 *
 * returns List
 **/
exports.salesByBrand = function() {
  return new Promise(function(resolve, reject) {




    var examples = {};
    examples['application/json'] = [ {
  "brandName" : "brandName",
  "popularity" : 0.8008281904610115,
  "sales" : 6.02745618307040320615897144307382404804229736328125
}, {
  "brandName" : "brandName",
  "popularity" : 0.8008281904610115,
  "sales" : 6.02745618307040320615897144307382404804229736328125
} ];
    if (Object.keys(examples).length > 0) {
      resolve(examples[Object.keys(examples)[0]]);
    } else {
      resolve();
    }
  });
}

