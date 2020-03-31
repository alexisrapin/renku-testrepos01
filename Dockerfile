FROM auwerxlab/renkulab:renku0.9.1-r3.6.0-77f0631

# Uncomment and adapt if code is to be included in the image
# COPY src /code/src

# Install system requirements
USER root
RUN apt-get -y update && apt-get clean && \
    apt-get -y install \
    libncurses5-dev \
    libncursesw5-dev \
    libxml2-dev \
    parallel \
    openssh-client \
    openssl \
    libgit2-dev \
    tk-dev \
    zlib1g-dev \
    texlive-full

# Add user to the sudoers
RUN adduser ${NB_USER} sudo && \
    echo "${NB_USER} ALL=(ALL:ALL) ALL" >> /etc/sudoers


# Enable R package management with packrat:

## Install the packrat R library
RUN Rscript -e "setwd('/home/rstudio'); install.packages('packrat', dependencies=TRUE); packrat::init(infer.dependencies = F)" && \
    chown -R ${NB_USER} /home/rstudio/packrat

## Install the required R libraries on the docker image
USER ${NB_USER}
COPY packrat/src /home/rstudio/packrat/src
COPY packrat/packrat.lock /home/rstudio/packrat/packrat.lock
RUN Rscript -e "setwd('/home/rstudio'); .libPaths(file.path('packrat', list.files('packrat', pattern = 'lib'), version$platform, paste(version$major, version$minor, sep = '.'))); packrat::restore()"

## Clean up the /home/rstudio directory to avoid confusion in nested R projects
RUN rm /home/rstudio/.Rprofile

# install the python dependencies
COPY requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt
