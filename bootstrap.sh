#!/usr/bin/env bash
set -Eeuo pipefail

[[ -z "${EPOCROOT:-}" ]] \
  && >&2 echo -e 'WARN: EPOCROOT not set! Was that actually on purpose?\n'
export EPOCROOT=${EPOCROOT:-$HOME/epocroot}

set -x

cd "$(dirname -- "$(realpath -- "$0")")"

BASH=$(command -v bash)
PERL=$(command -v perl)
GIT=$(command -v git)

export PATH="${PATH}:${PWD}/sbsv2/raptor/bin"

export PATH="${PATH}:'"${PWD}"'/sbsv2/raptor/bin"
export SBS_GCCE432BIN=$(dirname -- "$(command -v arm-none-symbianelf-gcc)")
export SBS_GCCX86BIN=$(dirname -- "$(command -v gcc)")
export SBS_GCCX86INC=$(dirname -- "$(command -v gcc)")/../include
export SBS_GCCX86LIB=$(dirname -- "$(command -v gcc)")/../lib
export SBS_SHELL="${BASH}"

pushd cross-plat-dev-utils/
"${PERL}" -I. build_raptor.pl >&2
popd

[[ ! -d openssl/ ]] \
  && "${GIT}" clone --depth 1 --branch OpenSSL_0_9_8-stable --single-branch https://github.com/openssl/openssl.git openssl/
if [[ ! -f openssl/libcrypto.a ]] ; then
  pushd openssl/
  ./Configure 'linux-elf:gcc -m32'
  make -j"$(nproc)" build_crypto
  popd
fi

readonly BLDS=("e32tools/elf2e32/group/bld.inf" "mifconv/group/bld.inf" "makesis/group/bld.inf")

for job in "${BLDS[@]}" ; do
  >&2 sbs -c tools2.nohrh -b "${job}" reallyclean
  >&2 sbs -c tools2.nohrh -b "${job}"
done

set +x
>&2 echo ''
>&2 echo '-------------'
>&2 echo ''

>&2 echo 'Okay, now export the following:'
echo ' export PATH="${PATH}:'"${PWD}"'/sbsv2/raptor/bin"'
echo ' export SBS_GCCE432BIN=/usr/bin'
echo ' export SBS_GCCX86BIN=/usr/bin'
echo ' export SBS_GCCX86INC=/usr/include'
echo ' export SBS_GCCX86LIB=/usr/lib'
echo ' export SBS_SHELL='"${BASH}"
echo ' export EPOCROOT='"${EPOCROOT}"

>&2 echo ''
>&2 echo 'Then, you can use SBSv2 like this:'
>&2 echo ' sbs -c gcce_armv5 -b /path/to/group/bld.inf'
