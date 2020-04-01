FROM openresty/openresty:xenial
RUN apt-get update && apt-get install -y git

# Test dependencies
RUN luarocks install busted

COPY . .
RUN luarocks make


