# A base docker image that includes juptyerhub and IPython master
#
# Build your own derivative images starting with
#
FROM ipython/scipystack

MAINTAINER Matt Edwards <matted@mit.edu>

RUN apt-get update
RUN apt-get install -y r-base r-cran-ggplot2 r-recommended python-rpy2 python2.7-rpy2 python-rpy python2.7-rpy

RUN apt-get install -y libsuitesparse-dev python-statsmodels python2.7-statsmodels python-pymc
RUN apt-get install -y python-tz python3-tz python2.7-pyparsing python-pyparsing python3-pyparsing

RUN apt-get install -y octave octave-data-smoothing octave-dataframe octave-econometrics octave-financial octave-financial octave-ga octave-gsl octave-image octave-linear-algebra octave-miscellaneous octave-nan octave-nlopt octave-nnet octave-odepkg octave-optim octave-signal octave-sockets octave-specfun octave-statistics octave-strings octave-symbolic octave-tsa

RUN pip install --upgrade numpy
RUN pip install --upgrade scipy
RUN pip install --upgrade pymc
RUN pip install --upgrade scikit-learn
RUN pip install git+https://github.com/njsmith/scikits-sparse.git
RUN pip install git+https://github.com/pymc-devs/pymc
RUN pip install --upgrade git+https://github.com/Theano/Theano.git
RUN pip install --upgrade statsmodels
RUN pip install --upgrade rpy2
RUN pip install terminado

RUN pip3 install --upgrade numpy
RUN pip3 install --upgrade scipy
RUN pip3 install --upgrade pymc # not on apt
RUN pip3 install --upgrade scikit-learn
RUN pip3 install git+https://github.com/njsmith/scikits-sparse.git
RUN pip3 install git+https://github.com/pymc-devs/pymc
RUN pip3 install --upgrade git+https://github.com/Theano/Theano.git
RUN pip3 install --upgrade statsmodels
RUN pip3 install --upgrade rpy2
RUN pip3 install terminado

RUN R -e 'source("http://bioconductor.org/biocLite.R"); biocLite("edgeR"); biocLite("DESeq2"); biocLite("DESeq");'

RUN mkdir -p /srv/

# install jupyterhub
ADD requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# Get R and other kernels, from jupyter/docker-demo-images.

RUN apt-get install -y vim emacs24-nox

# Julia and R Installation
RUN apt-get install software-properties-common python-software-properties -y && \
    add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" && \
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
    gpg -a --export E084DAB9 | apt-key add - && \
    add-apt-repository ppa:staticfloat/juliareleases && \
    add-apt-repository ppa:staticfloat/julia-deps && \
    apt-get update && \
    apt-get install julia -y && \
    apt-get install libnettle4 && \
    apt-get install -y r-base r-base-dev r-cran-rcurl libreadline-dev && \
    pip2 install rpy2 && pip3 install rpy2

# IJulia installation
# RUN julia -e 'Pkg.add("IJulia")'
# Julia packages
# RUN julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")'

# R installation
RUN echo 'options(repos=structure(c(CRAN="http://cran.rstudio.com")))' >> /etc/R/Rprofile.site
RUN echo "PKG_CXXFLAGS = '-std=c++11'" >> /etc/R/Makeconf
RUN echo "install.packages(c('ggplot2', 'XML', 'plyr', 'randomForest', 'Hmisc', 'stringr', 'RColorBrewer', 'reshape', 'reshape2'))" | R --no-save
RUN echo "install.packages(c('RCurl', 'devtools', 'dplyr'))" | R --no-save
RUN echo "install.packages(c('httr', 'knitr', 'packrat'))" | R --no-save
RUN echo "install.packages(c('rmarkdown', 'rvtest', 'testit', 'testthat', 'tidyr', 'shiny'))" | R --no-save
RUN echo "library(devtools); install_github('armstrtw/rzmq'); install_github('takluyver/IRdisplay'); install_github('takluyver/IRkernel'); IRkernel::installspec()" | R --no-save
RUN echo "library(devtools); install_github('hadley/lineprof')" | R --no-save
RUN echo "library(devtools); install_github('rstudio/rticles')" | R --no-save
RUN echo "library(devtools); install_github('jimhester/covr')" | R --no-save

RUN echo "install.packages(c('base64enc', 'Cairo', 'codetools', 'data.table', 'gridExtra', 'gtable', 'hexbin', 'jpeg', 'Lahman', 'lattice'))" | R --no-save
RUN echo "install.packages(c('MASS', 'PKI', 'png', 'microbenchmark', 'mgcv', 'mapproj', 'maps', 'maptools', 'mgcv', 'multcomp', 'nlme'))" | R --no-save
RUN echo "install.packages(c('nycflights13', 'quantreg', 'rJava', 'roxygen2', 'RSQLite', 'XML'))" | R --no-save

ADD configurable-http-proxy /tmp/configurable-http-proxy
WORKDIR /tmp/configurable-http-proxy
RUN npm install -g

WORKDIR /srv/
ADD . /srv/jupyterhub
WORKDIR /srv/jupyterhub/

RUN pip3 install .

RUN pip install git+https://github.com/Calysto/octave_kernel.git
RUN npm install -g ijavascript
RUN pip install git+https://github.com/takluyver/bash_kernel.git

# Copy kernels we just activated to the system-level location.
# RUN chmod -R a+rwx /root/.julia
RUN python2 -m IPython kernelspec install-self
RUN python3 -m IPython kernelspec install-self
RUN chmod -R a+r /root/.ipython
RUN cp -r /root/.ipython/kernels/* /usr/local/share/jupyter/kernels/

# Hacky...
RUN echo "matted ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "thashim ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /srv/jupyterhub/

EXPOSE 8000

# VOLUME /notebooks

# ONBUILD ADD jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py
ENTRYPOINT ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
