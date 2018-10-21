# Quagga-rtr - small containerised router

Alpine-based quagga router with OSPF turned on on all its interfaces

## Build

```
build.sh <dockerhub_username>
```

## Create


```
docker run -d --rm --cap-add=NET_ADMIN qrtr
```
