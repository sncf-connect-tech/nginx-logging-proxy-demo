This simple demo aims to demonstrate how to setup a simple `nginx` Docker service
(with `docker-compose` or `docker stack`) to log requests made to another service.

It originates from the following needs & constraints:
- we needed to debug some HTTP calls (which we suspected included CRLF control characters) made to a Docker-deployed endpoint
- we couldn't use external public services like [RequestBin](https://requestb.in) to inspect those requests because we were in a private isolated company infrastructure
- the awesome [httbin](https://httpbin.org) project [does not currently log requests it receives](https://github.com/kennethreitz/httpbin/issues/421), and `gunicorn` cannot dump the request body in its access logs

Hence we used a simple `nginx` Docker recipe to intercept and log requests.

# Demo
Let's start from the following basic `docker-compose.yaml`:

```
version: '3'
services:
  httpbin:
    build: ./httpbin
    ports:
      - "8000:8000"
```

Here `httpbin` plays the role of the final endpoint
(with the added advantage of logging the request `Content-Type`),
but really it could be any `docker-compose` / `docker stack` service for which you want to intercept requests.

Now, [with only 5 lines added to this YAML file](docker-compose.yaml), you can get the query string and body in your Docker logs:

- in one terminal:

    docker-compose up
    
- in another one:

    curl http://localhost:8000/post?foo=bar -d "$(echo -e 'TEST\r\n')"

Result:

    httpbin_1              | 172.20.0.3 [20/Mar/2018:12:34:46 +0000] POST /post?foo=bar HTTP/1.0 200 Content-Type: application/x-www-form-urlencoded
    nginx-logging-proxy_1  | 172.20.0.1 [20/Mar/2018:12:34:46 +0000] "POST /post?foo=bar HTTP/1.1" 200 TEST\x0D
