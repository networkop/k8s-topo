FROM alpine

RUN apk add --no-cache quagga

COPY examples/quagga-rtr/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
