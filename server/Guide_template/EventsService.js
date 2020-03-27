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

router.get('/api/events/ratio', function *(next) {
	const vals = db.entries;
	var count = [0,0,0]
	var total = 0;
	for(var i =0; i < vals.length; i++) {
		if(vals[i] == "view"){
			count[0]++;
		}else if(vals[i] == "cart"){
			count[1]++;
		}else if(vals[i] == "purchase"){
			count[2]++;
		}
		total++;
	}
	var ratios = [count[0]/total, count[1]/total, count[2]/total];
	console.log(ratios);
	this.body = ratios;
});

