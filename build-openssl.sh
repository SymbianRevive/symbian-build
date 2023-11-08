#!/usr/bin/env bash
set -Eeuo pipefail

set -x

[[ -d openssl/ ]] \
  && rm -rf openssl/
mkdir openssl/
>&2 pushd openssl/
wget -O- https://ftp.openssl.org/source/old/0.9.x/openssl-0.9.8zh.tar.gz |tar --strip-components=1 -xzf-
>&2 ./Configure no-shared no-dso 386 'linux-generic32:gcc -m32 -Werror=undef -Werror -DHAVE_LONG_LONG=1'
>&2 make -j"$(nproc)" build_crypto
>&2 popd
