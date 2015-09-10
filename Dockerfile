# FROM jupyter/notebook # This leads to dead kernels, which I don't understand.
FROM ipython/scipystack

MAINTAINER Matt Edwards <matted@mit.edu>

# Prepare basic system:
RUN apt-get update
RUN apt-get install -y python-tz python3-tz python2.7-pyparsing \
python-pyparsing python3-pyparsing libxrender1 fonts-dejavu gfortran \
gcc libzmq3-dev libzmq3 libxml2-dev libopenblas-dev liblapack-dev

RUN apt-get install -y octave octave-data-smoothing octave-dataframe \
octave-econometrics octave-financial octave-financial octave-ga \
octave-gsl octave-image octave-linear-algebra octave-miscellaneous \
octave-nan octave-nlopt octave-nnet octave-odepkg octave-optim \
octave-signal octave-sockets octave-specfun octave-statistics \
octave-strings octave-symbolic octave-tsa

# Hacky access control for the image:
RUN echo "matted ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "thashim ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN apt-get install -y vim emacs24-nox

# Get the latest Python packages for python2 and python3.
# Conda would be better, but I can't make it work correctly.
RUN pip2 install --upgrade pip
RUN pip2 install --upgrade numpy
RUN pip2 install --upgrade scipy
RUN pip2 install --upgrade pymc
RUN pip2 install --upgrade scikit-learn
RUN pip2 install git+https://github.com/pymc-devs/pymc
RUN pip2 install --upgrade statsmodels
RUN pip2 install terminado

RUN pip3 install --upgrade pip
RUN pip3 install --upgrade numpy
RUN pip3 install --upgrade scipy
RUN pip3 install --upgrade pymc
RUN pip3 install --upgrade scikit-learn
RUN pip3 install git+https://github.com/pymc-devs/pymc
RUN pip3 install --upgrade statsmodels
RUN pip3 install terminado

# New Julia and R installation (from
# https://github.com/jupyter/docker-demo-images/blob/master/Dockerfile),
# mixed with old approach that gets more recent versions from PPAs.
RUN apt-get install software-properties-common python-software-properties -y && \
    add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" && \
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
    gpg -a --export E084DAB9 | apt-key add - && \
    add-apt-repository ppa:staticfloat/juliareleases && \
    add-apt-repository ppa:staticfloat/julia-deps && \
    apt-get update && \
    apt-get install -y julia libnettle4 && \
    apt-get install -y r-base r-base-dev r-cran-rcurl libreadline-dev r-recommended r-cran-ggplot2 && \
    pip2 install rpy2 && pip3 install rpy2

RUN julia -e 'Pkg.add("IJulia")'
RUN julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")'
RUN julia -e 'Pkg.update()'

RUN echo 'options(repos=structure(c(CRAN="http://cran.rstudio.com")))' >> /etc/R/Rprofile.site
RUN echo "PKG_CXXFLAGS = '-std=c++11'" >> /etc/R/Makeconf

# Extra R packages:		     
RUN R -e 'source("http://bioconductor.org/biocLite.R"); biocLite("edgeR"); biocLite("DESeq2"); biocLite("DESeq");'
RUN echo "install.packages(c('ggplot2', 'XML', 'plyr', 'randomForest', 'Hmisc', 'stringr', 'RColorBrewer', 'reshape', 'reshape2'))" | R --no-save
RUN echo "install.packages(c('RCurl', 'devtools', 'dplyr'))" | R --no-save
RUN echo "install.packages(c('httr', 'knitr', 'packrat'))" | R --no-save
RUN echo "install.packages(c('rmarkdown', 'rvtest', 'testit', 'testthat', 'tidyr', 'shiny'))" | R --no-save
RUN echo "install.packages(c('base64enc', 'Cairo', 'codetools', 'data.table', 'gridExtra', 'gtable', 'hexbin', 'jpeg', 'Lahman', 'lattice'))" | R --no-save
RUN echo "install.packages(c('MASS', 'PKI', 'png', 'microbenchmark', 'mgcv', 'mapproj', 'maps', 'maptools', 'mgcv', 'multcomp', 'nlme'))" | R --no-save
RUN echo "install.packages(c('nycflights13', 'quantreg', 'rJava', 'roxygen2', 'RSQLite', 'XML'))" | R --no-save
RUN R -e 'install.packages(c("rzmq", "repr"), repos = c("http://irkernel.github.io/", getOption("repos")));'

# Install jupyterhub:
RUN mkdir -p /srv/
ADD requirements.txt /tmp/requirements.txt
RUN pip2 install -r /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

ADD configurable-http-proxy /tmp/configurable-http-proxy
WORKDIR /tmp/configurable-http-proxy
RUN npm install -g

WORKDIR /srv/
ADD . /srv/jupyterhub
WORKDIR /srv/jupyterhub/

RUN pip3 install .

# R kernel installation from http://irkernel.github.io/installation/:
RUN R -e 'install.packages(c("IRkernel", "IRdisplay"), repos = c("http://irkernel.github.io/", getOption("repos"))); IRkernel::installspec(user = FALSE);'

# Install some extra kernels:
RUN pip3 install git+https://github.com/Calysto/octave_kernel.git
# RUN npm install -g ijavascript # Doesn't seem to hook into Jupyter.
RUN pip2 install bash_kernel
RUN pip3 install bash_kernel
RUN python2 -m bash_kernel.install
RUN python3 -m bash_kernel.install

WORKDIR /srv/jupyterhub/

EXPOSE 8000

ENTRYPOINT ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
