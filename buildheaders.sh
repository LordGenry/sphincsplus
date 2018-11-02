#!/bin/bash

SPXDIR=$(realpath `dirname $0`)

if [ -e $SPXDIR/libspx.h ];then
  echo "$SPXDIR/libspx.h already exists, exiting."
  exit -1
fi

echo "#ifndef LIBSPX_H"  > $SPXDIR/libspx.h
echo "#define LIBSPX_H" >> $SPXDIR/libspx.h

cd $SPXDIR
cd ref

for PARAMS in ./params/*;do
  NAME=$(echo $PARAMS | sed "s/.*params-sphincs-/spx_/" | sed "s/-/_/g" | sed "s/\.h$//")
  HASH=$(echo $NAME | sed "s/spx_//" | sed "s/_.*//")

  if [ $HASH == "sha256" ];then  # We need to fix the openssl dependency first
    continue;
  fi

  echo "unsigned long long crypto_sign_${NAME}_secretkeybytes(void);" >> $SPXDIR/libspx.h
  echo "unsigned long long crypto_sign_${NAME}_publickeybytes(void);" >> $SPXDIR/libspx.h
  echo "unsigned long long crypto_sign_${NAME}_bytes(void);" >> $SPXDIR/libspx.h
  echo "unsigned long long crypto_sign_${NAME}_seedbytes(void);" >> $SPXDIR/libspx.h
  echo "int crypto_sign_${NAME}_seed_keypair(unsigned char *pk, unsigned char *sk, const unsigned char *seed);" >> $SPXDIR/libspx.h
  echo "int crypto_sign_${NAME}_keypair(unsigned char *pk, unsigned char *sk);" >> $SPXDIR/libspx.h
  echo "int crypto_sign_${NAME}(unsigned char *sm, unsigned long long *smlen, const unsigned char *m, unsigned long long mlen, const unsigned char *sk);" >> $SPXDIR/libspx.h
  echo "int crypto_sign_${NAME}_open(unsigned char *m, unsigned long long *mlen, const unsigned char *sm, unsigned long long smlen, const unsigned char *pk);" >> $SPXDIR/libspx.h
done

echo "#endif /* #define LIBSPX_H */" >> $SPXDIR/libspx.h
