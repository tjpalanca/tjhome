FROM rocker/verse:4.0.5
MAINTAINER TJ Palanca <mail@tjpalanca.com>

# Linux Dependencies
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libssh2-1-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    curl \
    lbzip2 \
    libpng-dev \
    libpq-dev \
    pandoc \
    libsodium-dev \
    libxt-dev \
    libmagick++-dev

# R Environment
RUN install2.r renv
COPY renv.lock renv.lock
RUN Rscript -e 'renv::restore()'

# Make package directory
RUN mkdir -p /src
WORKDIR /src

# Build assets
COPY DESCRIPTION DESCRIPTION
COPY NAMESPACE NAMESPACE
COPY .Rbuildignore .Rbuildignore
# COPY .covrignore .covrignore
# COPY data data
COPY inst inst
COPY tests tests
COPY man man
COPY R R
# COPY vignettes vignettes

# Install package
RUN Rscript -e "devtools::install('.', dependencies = TRUE, upgrade = FALSE)"

# Post-build assets
COPY scripts scripts
COPY README.md README.md
COPY README.Rmd README.Rmd
COPY NEWS.md NEWS.md
# COPY _pkgdown.yml _pkgdown.yml

# Command
CMD ["Rscript", "-e", "tjhome::job_maintain_ac_temp()"]
