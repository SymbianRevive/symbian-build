#!/usr/bin/env bash
set -Eeuo pipefail

set -x

[[ -d openssl/ ]] \
  && rm -rf openssl/
mkdir openssl/
>&/dev/null pushd openssl/
_MIRRORS=(
  https://ftp.man.lodz.pl/mirror/ftp.openssl.org/
  https://rhlx01.hs-esslingen.de/Mirrors/ftp.openssl.org/
  https://ftp.belnet.be/mirror/ftp.openssl.org/openssl-ftp/
  https://ftp.heanet.ie/mirrors/ftp.openssl.org/
  https://mirror.math.princeton.edu/pub/openssl/
)
_OPENSSL_DIST=openssl-0.9.8zh.tar.gz
rm -f "${_OPENSSL_DIST}"
aria2c --checksum=sha-256=f1d9f3ed1b85a82ecf80d0e2d389e1fda3fca9a4dba0bf07adbf231e1a5e2fd6 \
       --stderr=true -o ${_OPENSSL_DIST} "${_MIRRORS[@]/%/source/old/0.9.x/${_OPENSSL_DIST}}"
tar --strip-components=1 -xzf ${_OPENSSL_DIST}
rm -f "${_OPENSSL_DIST}"
./Configure no-shared no-dso 386 'linux-generic32:gcc -m32 -Werror=undef -Werror -DHAVE_LONG_LONG=1'
make -j"${MAKEJOBS}" ${MAKEFLAGS} build_crypto
>&/dev/null popd
