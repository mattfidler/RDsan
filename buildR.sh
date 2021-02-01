#!/bin/sh
#set -e -x

#echo 'options(repos = c(CRAN = "https://cloud.r-project.org/"),  download.file.method = "libcurl",  Ncpus = parallel::detectCores(logical=FALSE))' >> /etc/R/Rprofile.site


# Install TinyTeX (subset of TeXLive)
# From FAQ 5 and 6 here: https://yihui.name/tinytex/faq/
# Also install ae, parskip, and listings packages to build R vignettes
# wget -qO- \
#     "https://yihui.org/gh/tinytex/tools/install-unx.sh" | \
#     sh -s - --admin --no-path \
#     && ~/.TinyTeX/bin/*/tlmgr path add \
#     && tlmgr install metafont mfware inconsolata tex ae parskip listings xcolor \
#              epstopdf-pkg pdftexcmds kvoptions texlive-scripts grfext \
#     && tlmgr path add \
#     && Rscript -e "install.packages(\"tinytex\"); tinytex::r_texmf()"


# =====================================================================
# Install various versions of R-devel
# =====================================================================

# Environment variables from http://www.stats.ox.ac.uk/pub/bdr/memtests/README.txt
#export ASAN_OPTIONS='detect_leaks=0:detect_odr_violation=0'
export ASAN_OPTIONS='detect_leaks=0:detect_odr_violation=0'
export UBSAN_OPTIONS='print_stacktrace=1'
export RJAVA_JVM_STACK_WORKAROUND=0
export RGL_USE_NULL=true
export R_DONT_USE_TK=true

rm -rf /tmp/r-source

# Clone R-devel and download recommended packages
cd /tmp \
    && git clone --depth 1 https://github.com/wch/r-source.git \
    && r-source/tools/rsync-recommended

# Env vars used by configure. These settings are from `R CMD config CFLAGS`
# and CXXFLAGS, but without `-O0` and `-fdebug-prefix-map=...`, and with `-g`,
# `-O0`.
#export LIBnn=lib
# =============================================================================
# Customized settings for various builds
# =============================================================================
suffix="san"
# /usr/lib/gcc/x86_64-linux-gnu/10/
dirname="RD${suffix}"

# =============================================================================
# Build
# =============================================================================
rm -rf /usr/local/${dirname}/
mkdir -p /usr/local/${dirname}/

cd /tmp/r-source

# echo 'CXX="g++ -fsanitize=address,undefined,bounds-strict -fno-omit-frame-pointer"
# CFLAGS="-g -O0 -Wall -pedantic -mtune=native -fsanitize=address"
# DEFS=-DSWITCH_TO_REFCNT
# FFLAGS="-g -O0 -mtune=native"
# CXXFLAGS="-g -O0 -Wall -pedantic -mtune=native"
# MAIN_LDFLAGS="-fsanitize=address,undefined -pthread"
# ' >> /tmp/r-source/config.site

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
export FFLAGS="-g -O0"
export CXXFLAGS="-g -O0 -Wall -pedantic"
export MAIN_LDFLAGS="-fsanitize=address,undefined -pthread"

export configure_flags="--without-recommended-packages --disable-openmp"

./configure \
    --prefix=/usr/local/${dirname} \
    --enable-R-shlib \
    ${configure_flags}

# Do some stuff to simulate an SVN checkout.
# https://github.com/wch/r-source/wiki
(cd doc/manual && make front-matter html-non-svn)
echo -n 'Revision: ' > SVN-REVISION
git log --format=%B -n 1 \
  | grep "^git-svn-id"    \
  | sed -E 's/^git-svn-id: https:\/\/svn.r-project.org\/R\/[^@]*@([0-9]+).*$/\1/' \
  >> SVN-REVISION
echo -n 'Last Changed Date: ' >>  SVN-REVISION
git log -1 --pretty=format:"%ad" --date=iso | cut -d' ' -f1 >> SVN-REVISION

make
make install

# Clean up, but don't delete rsync'ed packages
git clean -xdf -e src/library/Recommended/
rm -f src/library/Recommended/Makefile

## Set Renviron to first use this version of R's site-library/, then library/,
## then use "vanilla" RD installation's library/. This makes it so we don't
## have to install recommended packages for every single flavor of R-devel.
echo "R_LIBS_SITE=\${R_LIBS_SITE-'/usr/local/${dirname}/lib/R/site-library:/usr/local/${dirname}/lib/R/library'}
R_LIBS_USER=~/${dirname}
MAKEFLAGS='--jobs=4'" \
    >> /usr/local/${dirname}/lib/R/etc/Renviron

# Create the site-library dir; packages installed after this point will go
# there.
mkdir -p "/usr/local/${dirname}/lib/R/site-library"


# Set default CRAN repo
echo 'options(repos = c(CRAN = "https://cloud.r-project.org/"),  download.file.method = "libcurl",  Ncpus = parallel::detectCores(logical=FALSE))' >> /usr/local/${dirname}/lib/R/etc/Rprofile.site

# Create RD and RDscript (with suffix) in /usr/local/bin
cp /usr/local/${dirname}/bin/R /usr/local/bin/RD${suffix}
cp /usr/local/${dirname}/bin/Rscript /usr/local/bin/RDscript${suffix}

/usr/local/${dirname}/bin/R -q -e 'install.packages(c("devtools"))'
/usr/local/${dirname}/bin/R -q -e 'setwd("/home/matt/src/RxODE");devtools::install_dev_deps()'

