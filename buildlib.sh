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

if [ -e $SPXDIR/libspx.h ];then
  echo "$SPXDIR/libspx.h already exists, exiting."
  exit -1
fi

cd $SPXDIR
mkdir -p libobj/tmp #XXX: Check if exists

echo "#ifndef LIBSPX_H"  > $SPXDIR/libspx.h
echo "#define LIBSPX_H" >> $SPXDIR/libspx.h

cd ref

for PARAMS in ./params/*;do
  NAME=$(echo $PARAMS | sed "s/.*params-sphincs-/spx_/" | sed "s/-/_/g" | sed "s/\.h$//")
  HASH=$(echo $NAME | sed "s/spx_//" | sed "s/_.*//")

  if [ $HASH == "sha256" ];then
    continue;
  fi

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
      -Dcrypto_secretkeybytes=crypto_secretkeybytes_$NAME \
      -Dcrypto_publickeybytes=crypto_publickeybytes_$NAME \
      -Dcrypto_bytes=crypto_bytes_$NAME \
      -Dcrypto_seedbytes=crypto_seedbytes_$NAME \
      -Dcrypto_sign_seed_keypair=crypto_sign_seed_keypair_$NAME \
      -Dcrypto_sign_keypair=crypto_sign_keypair_$NAME \
      -Dcrypto_sign_open=crypto_sign_open_$NAME \
      -Dcrypto_sign=crypto_sign_$NAME \
      -o $OFILE
  done
  ld -r *.o -o $NAME.o
  objcopy \
    --keep-global-symbol=crypto_secretkeybytes_$NAME \
    --keep-global-symbol=crypto_publickeybytes_$NAME \
    --keep-global-symbol=crypto_bytes_$NAME \
    --keep-global-symbol=crypto_seedbytes_$NAME \
    --keep-global-symbol=crypto_sign_seed_keypair_$NAME \
    --keep-global-symbol=crypto_sign_keypair_$NAME \
    --keep-global-symbol=crypto_sign_$NAME \
    --keep-global-symbol=crypto_sign_open_$NAME \
    $NAME.o ../$NAME.o
  rm $SPXDIR/libobj/tmp/*

#  echo "unsigned long long crypto_secretkeybytes(void);" >> $SPXDIR/libspx.h
#  echo "unsigned long long crypto_publickeybytes(void);" >> $SPXDIR/libspx.h
#  echo "unsigned long long crypto_keybytes(void);" >> $SPXDIR/libspx.h
#  echo "unsigned long long crypto_seedkeybytes(void);" >> $SPXDIR/libspx.h

done

cd $SPXDIR

gcc -shared $SPXDIR/libobj/*.o -o libspx.so

echo "#endif /* #define LIBSPX_H */" >> $SPXDIR/libspx.h

rm -r libobj
