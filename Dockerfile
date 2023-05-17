FROM node:18-alpine AS base
WORKDIR /chatgpt
RUN apk add --no-cache libc6-compat
RUN yarn config set registry 'https://registry.npm.taobao.org'
RUN apk add proxychains-ng
RUN apk update && apk add --no-cache git

EXPOSE 3000
ENV PROXY_URL=""
ENV OPENAI_API_KEY=""
ENV CODE=""

COPY package.json ./package.json
COPY yarn.lock ./yarn.lock
RUN yarn install

COPY . .
RUN yarn build

COPY .next/standalone/server.js ./server.js

CMD if [ -n "$PROXY_URL" ]; then \
        protocol=$(echo $PROXY_URL | cut -d: -f1); \
        host=$(echo $PROXY_URL | cut -d/ -f3 | cut -d: -f1); \
        port=$(echo $PROXY_URL | cut -d: -f3); \
        conf=/etc/proxychains.conf; \
        echo "strict_chain" > $conf; \
        echo "proxy_dns" >> $conf; \
        echo "remote_dns_subnet 224" >> $conf; \
        echo "tcp_read_time_out 15000" >> $conf; \
        echo "tcp_connect_time_out 8000" >> $conf; \
        echo "[ProxyList]" >> $conf; \
        echo "$protocol $host $port" >> $conf; \
        cat /etc/proxychains.conf; \
        proxychains -f $conf node server.js; \
    else \
        node server.js; \
    fi
