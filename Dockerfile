ARG DOCKER_IMAGE=alpine:3.19
FROM $DOCKER_IMAGE AS dev

ENV LUAJIT_VERSION v2.1

RUN apk add --no-cache git build-base cmake curl-dev zlib-dev zstd-dev \
		sqlite-dev postgresql-dev hiredis-dev leveldb-dev \
		gmp-dev jsoncpp-dev ninja ca-certificates

WORKDIR /usr/src/
RUN git clone --recursive https://github.com/jupp0r/prometheus-cpp && \
		cd prometheus-cpp && \
		cmake -B build \
			-DCMAKE_INSTALL_PREFIX=/usr/local \
			-DCMAKE_BUILD_TYPE=Release \
			-DENABLE_TESTING=0 \
			-GNinja && \
		cmake --build build && \
		cmake --install build && \
	cd /usr/src/ && \
	git clone --recursive https://github.com/libspatialindex/libspatialindex && \
		cd libspatialindex && \
		cmake -B build \
			-DCMAKE_INSTALL_PREFIX=/usr/local && \
		cmake --build build && \
		cmake --install build && \
	cd /usr/src/ && \
	git clone --recursive https://luajit.org/git/luajit.git -b ${LUAJIT_VERSION} && \
		cd luajit && \
		make amalg && make install && \
	cd /usr/src/

FROM dev as builder

COPY .git /usr/src/sandboxy/.git
COPY CMakeLists.txt /usr/src/sandboxy/CMakeLists.txt
COPY README.md /usr/src/sandboxy/README.md
COPY minetest.conf.example /usr/src/sandboxy/minetest.conf.example
COPY builtin /usr/src/sandboxy/builtin
COPY cmake /usr/src/sandboxy/cmake
COPY doc /usr/src/sandboxy/doc
COPY fonts /usr/src/sandboxy/fonts
COPY lib /usr/src/sandboxy/lib
COPY misc /usr/src/sandboxy/misc
COPY po /usr/src/sandboxy/po
COPY src /usr/src/sandboxy/src
COPY irr /usr/src/sandboxy/irr
COPY textures /usr/src/sandboxy/textures

WORKDIR /usr/src/sandboxy
RUN cmake -B build \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SERVER=TRUE \
		-DENABLE_PROMETHEUS=TRUE \
		-DBUILD_UNITTESTS=FALSE -DBUILD_BENCHMARKS=FALSE \
		-DBUILD_CLIENT=FALSE \
		-GNinja && \
	cmake --build build && \
	cmake --install build

FROM $DOCKER_IMAGE AS runtime

RUN apk add --no-cache curl gmp libstdc++ libgcc libpq jsoncpp zstd-libs \
				sqlite-libs postgresql hiredis leveldb && \
	adduser -D sandboxy --uid 30000 -h /var/lib/sandboxy && \
	chown -R sandboxy:sandboxy /var/lib/sandboxy

WORKDIR /var/lib/sandboxy

COPY --from=builder /usr/local/share/sandboxy /usr/local/share/sandboxy
COPY --from=builder /usr/local/bin/sandboxyserver /usr/local/bin/sandboxyserver
COPY --from=builder /usr/local/share/doc/sandboxy/minetest.conf /etc/sandboxy/sandboxy.conf
COPY --from=builder /usr/local/lib/libspatialindex* /usr/local/lib/
COPY --from=builder /usr/local/lib/libluajit* /usr/local/lib/
USER sandboxy:sandboxy

EXPOSE 30000/udp 30000/tcp
VOLUME /var/lib/sandboxy/ /etc/sandboxy/

ENTRYPOINT ["/usr/local/bin/sandboxyserver"]
CMD ["--config", "/etc/sandboxy/sandboxy.conf"]
