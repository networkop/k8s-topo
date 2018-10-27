FROM alpine

RUN apk add --no-cache git
RUN git clone https://github.com/networkop/k8s-topo.git
WORKDIR k8s-topo

RUN apk add --no-cache python3 build-base python3-dev openssl-dev libffi-dev libstdc++ nginx curl jq && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    pip3 install -r requirements.txt && \
    apk del build-base python3-dev openssl-dev libffi-dev && \ 
    rm -r /root/.cache && \
    rm -rf /var/cache/apk/*

COPY web/nginx.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /run/nginx

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
