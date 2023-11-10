#!/usr/bin/env bash
set -Eeuo pipefail

set -x

[[ -d openssl/ ]] \
  && rm -rf openssl/
mkdir openssl/
>&/dev/null pushd openssl/
wget -O- https://ftp.openssl.org/source/old/0.9.x/openssl-0.9.8zh.tar.gz |tar --strip-components=1 -xzf-
./Configure no-shared no-dso 386 'linux-generic32:gcc -m32 -Werror=undef -Werror -DHAVE_LONG_LONG=1'
make -j"${MAKEJOBS}" ${MAKEFLAGS} build_crypto
>&/dev/null popd
