const app = require('koa')();
const router = require('koa-router')();
const db = require('./db.json');

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
  var non_null = db.entries.filter((evt) => evt.category_code != "");
  this.body = [...new Set(non_null.map(item => (item.category_code)))];
});

/**
 * Lists all brands in the dataset by popularity within all possible event types (view, cart and purchase)
 *
 * returns List
 **/
router.get('/api/products/popularBrands', function *(next) {
  var sales = db.entries.filter((entry) => entry.brand != "").map(a => a.brand);

  this.body = foo(sales);

  function foo(arr) {
    var prev;
    var conjunto = [];
      
      arr.sort();
      for ( var i = 0; i < arr.length; i++ ) {
          if ( arr[i] !== prev ) {
            conjunto.push({'brand': arr[i], 'popularity': 1, "sales": 0});
          } else {
            conjunto[conjunto.length-1].popularity++;
          }
          prev = arr[i];
      }
      return conjunto;
  }
});



/**
 * Gets the average sale price of a brand
 *
 * brand String Brand name
 * returns List
 **/
router.get('/api/products/salePrice', function *(next) {
  const entries = db.entries.filter((entries) => entries.brand == brand && entries.event_type == "purchase");
    
  if (Object.keys(entries).length > 0) {

    let result = [...new Set(entries.filter((object,index) => index === entries.findIndex(obj => JSON.stringify(obj.product_id) === JSON.stringify(object.product_id))).map(item => item.price))];

    var media = Math.round(((result.reduce(function(total, num){
                  return parseFloat(total) + parseFloat(num);
                })/result.length) + Number.EPSILON) * 100) / 100;
    this.body = {
      "brand": {
        "brandName": brand,
        "popularity": 0,
        "sales": 0
      },
      "price": media,
      "category": {
        "name": ""
      }
    }
  }
});

/**
 * Lists number of sales made by each brand
 *
 * returns List
 **/
router.get('/api/products/salesByBrand', function *(next) {
  var sales = db.entries.filter((entry) => entry.brand != "" && entry.event_type == "purchase").map(a => a.brand);

  this.body = foo(sales);

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
});

app.use(router.routes());
app.use(router.allowedMethods());

app.listen(3000);

console.log('Worker started');