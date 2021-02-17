#!/bin/sh
#set -e -x

#export ASAN_OPTIONS='detect_leaks=0'
#Sys.setenv(ASAN_OPTIONS='detect_leaks=0')
#Sys.setenv(ASAN_OPTIONS='detect_leaks=0:detect_odr_violation=0')
export ASAN_OPTIONS='detect_leaks=0:detect_odr_violation=0'
export UBSAN_OPTIONS='print_stacktrace=1'
export RJAVA_JVM_STACK_WORKAROUND=0
export RGL_USE_NULL=true
export R_DONT_USE_TK=true

suffix="san"
dirname="RD${suffix}"


rm -rf ~/.R
mkdir ~/.R
echo 'CC = gcc -std=gnu99 -fsanitize=address,undefined -fno-omit-frame-pointer
F77 = gfortran -fsanitize=address
FC = gfortran -fsanitize=address
' > ~/.R/Makevars

export CC="gcc -std=gnu99 -fsanitize=address,undefined -fno-omit-frame-pointer"
export F77="gfortran -fsanitize=address"
export FC="gfortran -fsanitize=address"

export CXX="g++ -fsanitize=address,undefined,bounds-strict -fno-omit-frame-pointer"
export CFLAGS="-g -O0 -Wall -pedantic -fsanitize=address"
export DEFS=-DSWITCH_TO_REFCNT
export FFLAGS="-g -O0 -Wall -pedantic"
export CXXFLAGS="-g -O0 -Wall -pedantic"
export MAIN_LDFLAGS="-fsanitize=address,undefined -pthread"

export configure_flags="--without-recommended-packages --disable-openmp"

/usr/local/${dirname}/bin/R

