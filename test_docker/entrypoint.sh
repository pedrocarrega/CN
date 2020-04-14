#!/bin/bash
bash docker-entrypoint.sh mongod &
sleep 10s
mongoimport --db ecommerce --collection entries --type csv --file smallerLargeFile.csv --headerline
wait