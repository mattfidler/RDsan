#!/bin/sh
#set -e -x

export ASAN_OPTIONS='detect_leaks=0:detect_odr_violation=0'
export UBSAN_OPTIONS='print_stacktrace=1'
export RJAVA_JVM_STACK_WORKAROUND=0
export RGL_USE_NULL=true
export R_DONT_USE_TK=true

suffix="san"
dirname="RD${suffix}"


# echo 'CXX="g++ -fsanitize=address,undefined,bounds-strict -fno-omit-frame-pointer"
# CFLAGS="-g -O2 -Wall -pedantic -mtune=native -fsanitize=address"
# DEFS=-DSWITCH_TO_REFCNT
# FFLAGS="-g -O2 -mtune=native"
# CXXFLAGS="-g -O2 -Wall -pedantic -mtune=native"
# MAIN_LDFLAGS="-fsanitize=address,undefined -pthread"
# ' >> /tmp/r-source/config.site

# rm -rf ~/.R
# mkdir ~/.R
# echo 'CC = gcc -std=gnu99 -fsanitize=address,undefined -fno-omit-frame-pointer
# F77 = gfortran -fsanitize=address
# FC = gfortran -fsanitize=address
# ' > ~/.R/Makevars

export CC="gcc -std=gnu99 -fsanitize=address,undefined -fno-omit-frame-pointer"
export F77="gfortran -fsanitize=address"
export FC="gfortran -fsanitize=address"

export CXX="g++ -fsanitize=address,undefined,bounds-strict -fno-omit-frame-pointer"
export CFLAGS="-g -O0 -Wall -pedantic -mtune=native -fsanitize=address"
export DEFS=-DSWITCH_TO_REFCNT
export FFLAGS="-g -O0 -mtune=native"
export CXXFLAGS="-g -O0 -Wall -pedantic -mtune=native"
export MAIN_LDFLAGS="-fsanitize=address,undefined -pthread"

export configure_flags="--without-recommended-packages --disable-openmp"

/usr/local/${dirname}/bin/R -d "valgrind"

