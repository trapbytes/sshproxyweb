##
##
ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}


LABEL sshproxyweb.release="1.0.1" \
      sshproxyweb.release-date="2023-02-23" \
      sshproxyweb.release-type="production" \
      sshproxyweb.description="SSH JumpServer Via HTTP Web"


FROM buildpack-deps:bullseye

ENV OTP_VERSION="24.3.4.10" \
    REBAR3_VERSION="3.20.0" \
    USER_ID="sshproxyweb" \
    UID_GID="4609"

## set/get locales
RUN set -eux; \
	\
	export DEBIAN_FRONTEND=noninteractive; \
	export DEBCONF_NONINTERACTIVE_SEEN=true; \
	apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

#
# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
ENV LANG en_US.utf8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
#

# We need full control over the running user, including the UID, therefore we
# create the aiuser user id
#
RUN set -eux; \
	\
	export DEBIAN_FRONTEND=noninteractive; \
	export DEBCONF_NONINTERACTIVE_SEEN=true; \
	\
        addgroup --system --gid "${UID_GID}" "${USER_ID}"; \
	adduser --uid "${UID_GID}" -gid "${UID_GID}" --home "/home/${USER_ID}" --shell /bin/sh "${USER_ID}"; \
	\
	apt-get update && apt-get install -y \
	bash \
	curl \
	openssl \
	libssl-dev \
	autoconf \
	automake \
	gnupg \
	gcc \
	g++ \
	pkg-config \
	python3 \
	python3-pip \
	ssh \
	libssh-dev \
	zsh

# We'll install the build dependencies for erlang-odbc along with the erlang
# build process:
RUN set -xe \
	&& OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
	&& OTP_DOWNLOAD_SHA256="14d01d18601c1460de847ff8c4434d8e20fc322b5291766c3fe35f50907bb7a9" \
	&& runtimeDeps='libodbc1 \
			libsctp1 \
			libwxgtk3.0 \
			libwxgtk-webview3.0-gtk3-0v5' \
	&& buildDeps='unixodbc-dev \
			libsctp-dev \
			libwxgtk-webview3.0-gtk3-dev' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $runtimeDeps \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
	&& echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
	&& export ERL_TOP="/usr/src/otp_src_${OTP_VERSION%%@*}" \
	&& mkdir -vp $ERL_TOP \
	&& tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1 \
	&& rm otp-src.tar.gz \
	&& ( cd $ERL_TOP \
	  && ./otp_build autoconf \
	  && gnuArch="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" \
	  && ./configure --build="$gnuArch" \
	  && make -j$(nproc) \
	  && make -j$(nproc) docs DOC_TARGETS=chunks \
	  && make install install-docs DOC_TARGETS=chunks ) \
	&& find /usr/local -name examples | xargs rm -rf \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf $ERL_TOP /var/lib/apt/lists/*

# extra useful tools here: rebar & rebar3

ENV REBAR_VERSION="2.6.4"

RUN set -xe \
	&& REBAR_DOWNLOAD_URL="https://github.com/rebar/rebar/archive/${REBAR_VERSION}.tar.gz" \
	&& REBAR_DOWNLOAD_SHA256="577246bafa2eb2b2c3f1d0c157408650446884555bf87901508ce71d5cc0bd07" \
	&& mkdir -p /usr/src/rebar-src \
	&& curl -fSL -o rebar-src.tar.gz "$REBAR_DOWNLOAD_URL" \
	&& echo "$REBAR_DOWNLOAD_SHA256 rebar-src.tar.gz" | sha256sum -c - \
	&& tar -xzf rebar-src.tar.gz -C /usr/src/rebar-src --strip-components=1 \
	&& rm rebar-src.tar.gz \
	&& cd /usr/src/rebar-src \
	&& ./bootstrap \
	&& install -v ./rebar /usr/local/bin/ \
	&& rm -rf /usr/src/rebar-src

RUN set -xe \
	&& REBAR3_DOWNLOAD_URL="https://github.com/erlang/rebar3/archive/${REBAR3_VERSION}.tar.gz" \
	&& REBAR3_DOWNLOAD_SHA256="53ed7f294a8b8fb4d7d75988c69194943831c104d39832a1fa30307b1a8593de" \
	&& mkdir -p /usr/src/rebar3-src \
	&& curl -fSL -o rebar3-src.tar.gz "$REBAR3_DOWNLOAD_URL" \
	&& echo "$REBAR3_DOWNLOAD_SHA256 rebar3-src.tar.gz" | sha256sum -c - \
	&& tar -xzf rebar3-src.tar.gz -C /usr/src/rebar3-src --strip-components=1 \
	&& rm rebar3-src.tar.gz \
	&& cd /usr/src/rebar3-src \
	&& HOME=$PWD ./bootstrap \
	&& install -v ./rebar3 /usr/local/bin/ \
	&& rm -rf /usr/src/rebar3-src
#
#
COPY /erl /opt/local/build/sshproxyweb/
#
RUN set -eux; \
	chown -R ${USER_ID}:${USER_ID} /opt/local/build/sshproxyweb/ \
	&& cd /opt/local/build/sshproxyweb/ \
	&& make distclean \
	&& make \
	&& chown -R ${USER_ID}:${USER_ID} /opt/local/build/sshproxyweb/ 


#
# need root to remove the pkgs and clean up
#USER root
RUN set -eux; \
	apt-get remove -y --allow-unauthenticated \
		gcc \
		g++ \
		autoconf \
		automake ; \
	apt-get autoremove -y

#
EXPOSE 8090/tcp
# reset our user to be desired user id
USER "${USER_ID}"

#
## launch command
CMD ["/opt/local/build/sshproxyweb/_rel/wterm_release/bin/wterm_release", "console"]
