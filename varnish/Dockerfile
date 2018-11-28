FROM debian

ADD install.sh install.sh
RUN chmod +x install.sh && sh ./install.sh && rm install.sh

# dependencies required for building VMOD (Varnish modules)
ENV VMOD_BUILD_DEPS \
		autoconf-archive \
		automake \
		autotools-dev \
		libtool \
		make \
		pkg-config \
		python-docutils \
                build-essential

# install vmod-varnish-modules
RUN set -eux; \
	\
	fetchDeps=' \
		ca-certificates \
		wget \
	'; \
	buildDeps=" \
		$VMOD_BUILD_DEPS \
		dpkg-dev \
	"; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps $buildDeps; \
	rm -rf /var/lib/apt/lists/*; \
	\
	wget -O vmod-varnish-modules.tar.gz "https://github.com/varnish/varnish-modules/archive/0.15.0.tar.gz"; \
	mkdir -p /usr/local/src/vmod-varnish-modules; \
	tar -zxf vmod-varnish-modules.tar.gz -C /usr/local/src/vmod-varnish-modules --strip-components=1; \
	rm vmod-varnish-modules.tar.gz; \
	\
	cd /usr/local/src/vmod-varnish-modules; \
        ls -la ; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
        ./bootstrap; \
	./configure \
		--build="$gnuArch" \
	; \
	make -j "$(nproc)"; \
	make install; \
	\
	cd /; \
	rm -rf /usr/local/src/vmod-varnish-modules; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps $buildDeps

VOLUME ["/var/lib/varnish", "/etc/varnish"]
EXPOSE 80

ADD start.sh /start.sh
RUN chmod +x /start.sh

ADD default.vcl /etc/varnish/

CMD ["/start.sh"]
