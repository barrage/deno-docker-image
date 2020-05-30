#### BUILD stage ####
FROM rust:1.42.0 as builder

LABEL maintainer="Ivan Rimac <ivan@barrage.net>"

# change workdir to dedicated workspace
WORKDIR /denoland

# fetch the compressed source of deno
ADD https://github.com/denoland/deno/releases/download/v1.0.1/deno_src.tar.gz .

RUN tar xvzf ./deno_src.tar.gz

# clean up after
RUN mv ./deno/* .
RUN rm -Rf ./deno ./deno_src.tar.gz

# build deno
RUN cargo build -vv

RUN cp ./target/debug/deno /usr/local/bin

#### FINAL STAGE ####
FROM phusion/baseimage:0.10.2

ARG USER_ID
ARG GROUP_ID

ENV HOME /denoland

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} deno \
	&& useradd -u ${USER_ID} -g deno -s /bin/bash -m -d /denoland deno

COPY --from=builder /denoland/target/debug/deno /bin

VOLUME ["/denoland"]

# main command to run when container starts
CMD ["deno"]
