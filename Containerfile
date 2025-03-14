# syntax=docker/dockerfile:latest

FROM quay.io/fedora/fedora:latest
COPY assets/dnf.conf /etc/dnf/dnf.conf
COPY assets/requirements.lst /packages.txt

RUN --mount=type=tmpfs,target=/var/lib/dnf \
	--mount=type=tmpfs,target=/var/log \
	--mount=type=tmpfs,target=/tmp \
	--mount=type=cache,id=dnf,sharing=locked,target=/var/cache/libdnf5 \
	--mount=type=tmpfs,target=/tmp \
	   dnf install -y $(< /packages.txt) \
	&& python3 -m pip install sqlobject

ENV PATH="/usr/lib/ccache:${PATH}" CCACHE_DIR=/var/cache/ccache CCACHE_MAXSIZE=50G
RUN mkdir -p /usr/lib/ccache \
 && ln -s /usr/bin/ccache /usr/lib/ccache/cc \
 && ln -s /usr/bin/ccache /usr/lib/ccache/gcc \
 && ln -s /usr/bin/ccache /usr/lib/ccache/g++

COPY builder /builder
WORKDIR /builder
VOLUME /data/dist /data/storage /var/cache/ccache

ENTRYPOINT []
CMD ["/usr/bin/bash", "/builder/build.sh"]
