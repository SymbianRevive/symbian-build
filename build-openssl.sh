#!/usr/bin/env bash
set -Eeuo pipefail

set -x

[[ ! -d openssl/ ]] \
  && git clone --depth 1 --branch OpenSSL_0_9_8-stable --single-branch https://github.com/openssl/openssl.git openssl/
if [[ ! -f openssl/libcrypto.a ]] ; then
  pushd openssl/
  ./Configure 'linux-elf:gcc -m32'
  make -j"$(nproc)" build_crypto
  popd
fi
