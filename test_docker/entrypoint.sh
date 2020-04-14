#!/bin/bash
bash docker-entrypoint.sh mongod &
sleep 10s
mongoimport --db ecommerce --collection entries --type csv --file smallerLargeFile.csv --fields="event_time,event_type,product_id,category_id,category_code,brand,price,user_id,user_session"
rm -f smallerLargeFile.csv
wait