FROM openresty/openresty:xenial
RUN apt-get update && apt-get install -y git

# Test dependencies
RUN luarocks install busted
# Manually install the dependency lua-resty-statsd, since luarocks install
# is currently broken.
RUN git clone https://github.com/landakram/lua-resty-statsd.git && \
    cd lua-resty-statsd && \
    luarocks make

COPY . .
RUN luarocks make


