'use strict';
const db = require('./db.json'); //to remove later
//list categories
var non_null = db.entries.filter((evt) => evt.category_code != "");
var uniques = [...new Set(non_null.map(item => item.category_code))];

/**
 * Lists all product categories made available in the dataset
 *
 * returns List
 **/
exports.listCategories = function() {
  var non_null = db.entries.filter((evt) => evt.category_code != "");
  var uniques = [...new Set(non_null.map(item => item.category_code))];
}


/**
 * Lists all brands in the dataset by popularity within all possible event types (view, cart and purchase)
 *
 * returns List
 **/
exports.mostPopularBrands = function() {
  var sales = db.entries.filter((entry) => entry.brand != "").map(a => a.brand);
  sales.sort();

  var result = foo(sales);

  function foo(arr) {
    var prev;
    var conjunto = [];
      
      arr.sort();
      for ( var i = 0; i < arr.length; i++ ) {
          if ( arr[i] !== prev ) {
            conjunto.push({'brand': arr[i], 'count': 1});
          } else {
            conjunto[conjunto.length-1].count++;
          }
          prev = arr[i];
      }
      return conjunto;
  }
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
  var sales = db.entries.filter((entry) => entry.event_type == "purchase");
}

