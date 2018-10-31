#!/bin/bash

SPXDIR=$(realpath `dirname $0`)
CC="gcc"
CFLAGS="-Wall -Wextra -Wpedantic -O3"

cd $SPXDIR

if [ -e $SPXDIR/libobj ];then
  echo "$SPXDIR/libobj already exists, exiting."
  exit -1
fi

mkdir -p libobj/tmp #XXX: Check if exists

cd ref

for PARAMS in ./params/*;do
  NAME=$(echo $PARAMS | sed "s/.*params-sphincs-/spx_/" | sed "s/-/_/g" | sed "s/\.h$//")
  HASH=$(echo $NAME | sed "s/spx_//" | sed "s/_.*//")

  echo Building $NAME

  cd $SPXDIR/ref
  cp *.c *.h $SPXDIR/libobj/tmp/
  rm $SPXDIR/libobj/tmp/rng.c
  rm $SPXDIR/libobj/tmp/hash_*.c
  cp hash_$HASH.c $SPXDIR/libobj/tmp

  cd $SPXDIR/libobj/tmp

  for CFILE in *.c;do
    OFILE=$(echo $CFILE | sed "s/c$/o/")
    $CC $CFLAGS -c $CFILE \
      -Dcrypto_sign_seed_keypair=crypto_sign_seed_keypair_$NAME \
      -Dcrypto_sign_keypair=crypto_sign_keypair_$NAME \
      -Dcrypto_sign_open=crypto_sign_open_$NAME \
      -Dcrypto_sign=crypto_sign_$NAME \
      -o $OFILE
  done
  ld -r *.o -o $NAME.o
  objcopy \
    --keep-global-symbol=crypto_sign_seed_keypair_$NAME \
    --keep-global-symbol=crypto_sign_keypair_$NAME \
    --keep-global-symbol=crypto_sign_$NAME \
    --keep-global-symbol=crypto_sign_open_$NAME \
    $NAME.o ../$NAME.o
  rm $SPXDIR/libobj/tmp/*
done

cd $SPXDIR

gcc -shared $SPXDIR/libobj/*.o -o libspx.so
rm -r libobj
