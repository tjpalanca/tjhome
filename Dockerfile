FROM tjpalanca/apps:tjutils-v0.5.1
MAINTAINER TJ Palanca <mail@tjpalanca.com>

# Make package directory
RUN mkdir -p /tjhome
WORKDIR /tjhome

# R Environment
RUN install2.r renv
COPY renv.lock renv.lock
RUN Rscript -e 'renv::restore()'

# Build assets
COPY DESCRIPTION DESCRIPTION
COPY NAMESPACE NAMESPACE
COPY .Rbuildignore .Rbuildignore
COPY man man
COPY R R

# Install package
RUN Rscript -e "devtools::install('.', dependencies = TRUE, upgrade = FALSE)"

# Post-build assets
COPY scripts scripts
COPY README.md README.md
COPY README.Rmd README.Rmd
COPY NEWS.md NEWS.md
