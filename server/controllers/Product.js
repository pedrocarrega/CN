'use strict';

var utils = require('../utils/writer.js');
var Product = require('../service/ProductService');

module.exports.listCategories = function listCategories (req, res, next) {
  Product.listCategories()
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};

module.exports.mostPopularBrands = function mostPopularBrands (req, res, next) {
  Product.mostPopularBrands()
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};

module.exports.salePrice = function salePrice (req, res, next) {
  var brand = req.swagger.params['brand'].value;
  Product.salePrice(brand)
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};

module.exports.salesByBrand = function salesByBrand (req, res, next) {
  Product.salesByBrand()
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};
