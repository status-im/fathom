FROM node:alpine AS assetbuilder
WORKDIR /app
COPY package*.json ./
COPY gulpfile.js ./
COPY assets/ ./assets/
RUN npm install && NODE_ENV=production ./node_modules/gulp/bin/gulp.js

FROM golang:1.12.14-alpine3.9 AS binarybuilder
RUN apk add --no-cache git gcc musl-dev make
RUN go get -u github.com/gobuffalo/packr/packr
RUN go get -u github.com/usefathom/fathom
WORKDIR /go/src/github.com/usefathom/fathom
COPY . /go/src/github.com/usefathom/fathom
COPY --from=assetbuilder /app/assets/build ./assets/build
RUN make docker

FROM alpine:3.14
EXPOSE 8080
HEALTHCHECK --retries=10 CMD ["wget", "-qO-", "http://localhost:8080/health"]
RUN apk add --update --no-cache bash ca-certificates
WORKDIR /app
COPY --from=binarybuilder /go/src/github.com/usefathom/fathom/fathom .
CMD ["./fathom", "server"]
