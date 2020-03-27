'use strict';


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
 * Gets the average sale price by brand
 *
 * brand String Brand name
 * returns List
 **/
exports.salePrice = function(brand) {
  return new Promise(function(resolve, reject) {
    var examples = {};
    examples['application/json'] = [ {
  "price" : 0.8008281904610115,
  "category" : {
    "name" : "name"
  },
  "brand" : {
    "brandName" : "brandName",
    "popularity" : 0.8008281904610115,
    "sales" : 6.02745618307040320615897144307382404804229736328125
  }
}, {
  "price" : 0.8008281904610115,
  "category" : {
    "name" : "name"
  },
  "brand" : {
    "brandName" : "brandName",
    "popularity" : 0.8008281904610115,
    "sales" : 6.02745618307040320615897144307382404804229736328125
  }
} ];
    if (Object.keys(examples).length > 0) {
      resolve(examples[Object.keys(examples)[0]]);
    } else {
      resolve();
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

