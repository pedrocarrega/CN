FROM mhart/alpine-node:7.10.1

WORKDIR /srv
ADD . .
RUN npm install
RUN npm install mongodb

EXPOSE 3000
CMD ["node", "server.js"]
