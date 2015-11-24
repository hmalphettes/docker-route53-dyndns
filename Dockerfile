## DynDNS for Docker with Route53
##
## Dynamic DNS counterpart of James Wilder's nginx-proxy for docker:
## [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy).
##
## Containerize cli53
## Discover the expected DNS names following the same conventions than jwilder/nginx-proxy
## Generate the DNS A record file and call cli53 to process it

FROM alpine
MAINTAINER hugues@sutoiku.com

WORKDIR /app
RUN apk add --update python-dev wget curl && \
	pip install cli53 && \
	wget -P /usr/local/bin https://github.com/hmalphettes/nginx-proxy/releases/download/0.0.0/docker-gen && \
	chmod +x /usr/local/bin/docker-gen

ADD cli53routes.tmpl /app/cli53routes.tmpl

ENV DOCKER_HOST unix:///tmp/docker.sock

CMD /usr/local/bin/docker-gen -watch -notify "/bin/bash /tmp/cli53routes" /app/cli53routes.tmpl /tmp/cli53routes
