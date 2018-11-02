#!/bin/bash

SPXDIR=$(realpath `dirname $0`)
CC="gcc"
CFLAGS="-Wall -Wextra -Wpedantic -O3"


if [ -e $SPXDIR/libobj ];then
  echo "$SPXDIR/libobj already exists, exiting."
  exit -1
fi

if [ -e $SPXDIR/libspx.so ];then
  echo "$SPXDIR/libspx.so already exists, exiting."
  exit -1
fi

cd $SPXDIR

if [ ! -e $SPXDIR/libspx.h ];then
  ./buildheaders.sh
fi

mkdir -p libobj/tmp #XXX: Check if exists

cd ref

for PARAMS in ./params/*;do
  NAME=$(echo $PARAMS | sed "s/.*params-sphincs-/spx_/" | sed "s/-/_/g" | sed "s/\.h$//")
  HASH=$(echo $NAME | sed "s/spx_//" | sed "s/_.*//")

  if [ $HASH == "sha256" ];then  # We need to fix the openssl dependency first
    continue;
  fi

  echo Building $NAME

  cd $SPXDIR/ref
  cp *.c *.h $SPXDIR/libobj/tmp/
  rm $SPXDIR/libobj/tmp/rng.{c,h}
  rm $SPXDIR/libobj/tmp/PQCgenKAT_sign.c
  rm $SPXDIR/libobj/tmp/hash_*.c
  rm $SPXDIR/libobj/tmp/params.h
  cp hash_$HASH.c $SPXDIR/libobj/tmp
  cp $PARAMS $SPXDIR/libobj/tmp/params.h

  cd $SPXDIR/libobj/tmp

  for CFILE in *.c;do
    OFILE=$(echo $CFILE | sed "s/c$/o/")
    $CC $CFLAGS -c $CFILE \
      -Dcrypto_sign_secretkeybytes=crypto_sign_${NAME}_secretkeybytes \
      -Dcrypto_sign_publickeybytes=crypto_sign_${NAME}_publickeybytes \
      -Dcrypto_sign_bytes=crypto_sign_${NAME}_bytes \
      -Dcrypto_sign_seedbytes=crypto_sign_${NAME}_seedbytes \
      -Dcrypto_sign_seed_keypair=crypto_sign_${NAME}_seed_keypair \
      -Dcrypto_sign_keypair=crypto_sign_${NAME}_keypair \
      -Dcrypto_sign_open=crypto_sign_${NAME}_open \
      -Dcrypto_sign=crypto_sign_${NAME} \
      -o $OFILE
  done
  ld -r *.o -o $NAME.o
  objcopy \
    --keep-global-symbol=crypto_sign_${NAME}_secretkeybytes \
    --keep-global-symbol=crypto_sign_${NAME}_publickeybytes \
    --keep-global-symbol=crypto_sign_${NAME}_bytes \
    --keep-global-symbol=crypto_sign_${NAME}_seedbytes \
    --keep-global-symbol=crypto_sign_${NAME}_seed_keypair \
    --keep-global-symbol=crypto_sign_${NAME}_keypair \
    --keep-global-symbol=crypto_sign_${NAME} \
    --keep-global-symbol=crypto_sign_${NAME}_open \
    $NAME.o ../$NAME.o
  rm $SPXDIR/libobj/tmp/*

done

cd $SPXDIR

gcc -shared $SPXDIR/libobj/*.o -o libspx.so

rm -r libobj
