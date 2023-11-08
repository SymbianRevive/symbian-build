#!/usr/bin/env bash
set -Eeuo pipefail

set -x

[[ ! -d openssl/ ]] \
  && git clone --depth 1 --branch OpenSSL_0_9_8-stable --single-branch https://github.com/openssl/openssl.git openssl/
if [[ ! -f openssl/libcrypto.a ]] ; then
  pushd openssl/
  ./Configure no-shared no-dso 386 'linux-generic32:gcc -m32 -Werror=undef -DHAVE_LONG_LONG=1'
  make -j"$(nproc)" build_crypto
  popd
fi
