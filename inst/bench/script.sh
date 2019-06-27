#!/bin/bash

# don't forget to set your GITHUB_PAT before running this script
<<<<<<< HEAD
[ -n "${GITHUB_PAT}" ] || { echo >&2 "Set GITHUB_PAT first!"; exit 1; }
=======
[ -n "$GITHUB_PAT" ] || echo >&2 "Set GITHUB_PAT first!" && exit 2
>>>>>>> fwf-bench

sudo apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
    apt-transport-https \
    build-essential \
    curl \
    gfortran \
    libatlas-base-dev \
    libbz2-dev \
    libcairo2 \
    libcurl4-openssl-dev \
    libicu-dev \
    liblzma-dev \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libpcre3-dev \
    libssl-dev \
    libssh2-1-dev \
    libtcl8.6 \
    libtiff5 \
    libtk8.6 \
    libx11-6 \
    libxml2-dev
    libxt6 \
    locales \
    sudo \
    tzdata \
    wget \
    zlib1g-dev && \
    sudo rm -rf /var/lib/apt/lists/*

OS_IDENTIFIER=ubuntu-1804
R_VERSION=3.6.0

wget -O R-${R_VERSION}.tar.gz https://cdn.rstudio.com/r/${OS_IDENTIFIER}/R-${R_VERSION}-${OS_IDENTIFIER}.tar.gz 
sudo mkdir -p /opt/R 
sudo chown ubuntu /opt/R
tar zx -C /opt/R -f ./R-${R_VERSION}.tar.gz 
rm R-${R_VERSION}.tar.gz
export PATH=/opt/R/${R_VERSION}/bin:$PATH

# download and extract data
mkdir ~/data/
wget -O ~/data/trip_fare.7z https://archive.org/download/nycTaxiTripData2013/trip_fare.7z && \
  sudo apt install p7zip-full && \
  cd ~/data && \
  7z x trip_fare.7z &> data.out
# fix trailing space in header for every file
ls *trip_fare*.csv | xargs -P 16 sed -i '1 s/, /,/g'

# clone vroom
git clone https://jimhester:${GITHUB_PAT}/github.com/r-lib/vroom.git
cd vroom

# set common Rprofile options
echo "options(repos = 'https://cran.rstudio.org', Ncpus = 16)" > ~/.Rprofile

# install R dependencies
Rscript -e 'install.packages("remotes")' \
  -e 'remotes::install_local(dependencies = TRUE)'

# install additional packages for benchmarking
Rscript -e 'remotes::install_cran(c("data.table", "callr", "here", "sessioninfo"))'
sudo apt-get install -y pigz zstd

make bench

PKG_VERSION=$(perl -ne 'print $1 if /Version: (.*)/' DESCRIPTION)
git checkout -b bench/R-${R_VERSION}_vroom-${PKG_VERSION}

git config --global user.email "james.f.hester@gmail.com"
git config --global user.name "Jim Hester"

git commit -m 'Update benchmarks' inst/bench/*tsv
