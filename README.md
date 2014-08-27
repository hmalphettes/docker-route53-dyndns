DynDNS for Docker with Route53
==============================

This is the Dynamic DNS counterpart of James Wilder's nginx-proxy for docker: [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy).

* Listen to start events of containers on the docker socket.
* Outputs a shell script with the list of expected A Records according to the VIRTUAL_HOST environment variables of the started containers.
* Execute the script to create or update the list of A Records with Route53.

The current template does not generate hosted zones.

https://github.com/jwilder/docker-gen is in charge of listening to the docker events and generating the file.
https://github.com/barnybug/cli53 is in charge of talking to Route53.

Setup
=====

Environment variables:

* `AWS_ACCESS_KEY_ID` Required
* `AWS_SECRET_ACCESS_KEY` Required
* `PUBLIC_IP` The IP of the generated records. Optional
* `PRIVATE_TOP_ZONES` Space separated list of private top-zone and hostnames, optional.
* `DRY_ROUTE53` when defined, just echo the commands that we would run.

When `PUBLIC_IP` is not defined, call AWS's EC2 metadataservice to get it.

When `PRIVATE_TOP_ZONES` is not defined its default value is: `localhost local priv private`

Example run
===========
```
docker run --rm --name route53 \
	-v /var/run/docker.sock:/tmp/docker.sock
	-e AWS_ACCESS_KEY_ID=ABC -e AWS_SECRET_ACCESS_KEY=DEF
	-t hmalphettes/docker-route53-dyndns
```

Example setup with fig
======================
```
nginx:
  image: jwilder/nginx-proxy
  ports:
    - "80:80"
  volumes:
    - /var/run/docker.sock:/tmp/docker.sock
route53:
  image: hmalphettes/docker-route53-dyndns
  environment:
  	- AWS_ACCESS_KEY_ID: ABC
  	- AWS_SECRET_ACCESS_KEY: DEF
  volumes:
    - /var/run/docker.sock:/tmp/docker.sock
web00:
  image: progrium/webapp
  environment:
    VIRTUAL_HOST: localhost,dev01.foo.bar
```

Example generated script:
=========================
```
#!/bin/sh
[ -z "$PUBLIC_IP" ] && PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
[ -z "$PRIVATE_TOP_ZONES" ] && PRIVATE_TOP_ZONES="localhost local priv private"

host=dev01.foo.bar
topzone=$(echo "${host##*.}")
tenant=$(echo $host | cut -f1 -d'.')
zone=$(echo "${host#*.}")
if [ "${PRIVATE_TOP_ZONES#*$topzone}" != "$PRIVATE_TOP_ZONES" -o "$tenant" = "$zone" ]; then
    echo "Skipping private hostname $host"
else
    cmd="cli53 rrcreate $zone $tenant A $PUBLIC_IP --ttl 300 --replace"
    [ -z "$DRY_ROUTE53" ] && $cmd || echo "DRYRUN: $cmd"
fi
```

Minimum IAM policy:
===================
```
{
  "Effect": "Allow",
  "Action": [
    "route53:ChangeResourceRecordSets",
    "route53:GetChange",
    "route53:GetHostedZone",
    "route53:ListResourceRecordSets"
  ],
  "Resource": "arn:aws:route53:::hostedzone/*"
},
{
  "Effect": "Allow",
  "Action": [
    "route53:ListHostedZones"
  ],
  "Resource": "*"
}
```

COPYRIGHT: Sutoiku Inc 2014
LICENSE: MIT
