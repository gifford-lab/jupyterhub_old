# A base docker image that includes juptyerhub and IPython master
#
# Build your own derivative images starting with
#
# Scipystack has more features installed, but jupyterhub has Python 2 kernel.
# FROM ipython/scipystack
# FROM jupyter/jupyterhub:latest
FROM ipython/ipython

MAINTAINER Matt Edwards <matted@mit.edu>

# Get some fun packages.
# Postpone this for now.  And we have full scipystack now.
RUN apt-get update
RUN apt-get install -y r-base r-cran-ggplot2 r-recommended
RUN apt-get install -y python-rpy2 python2.7-rpy2 python-rpy python2.7-rpy

RUN apt-get install -y libsuitesparse-dev 
RUN apt-get install -y liblapack-dev liblapack3 libblas-dev libblas3 libatlas-dev libatlas-base-dev libatlas3-base cython python-numpy python3-numpy fortran-compiler python-statsmodels python2.7-statsmodels python-sklearn python2.7-sklearn python-pymc
RUN apt-get install -y python-tz python3-tz python2.7-pyparsing python-pyparsing python3-pyparsing

# RUN pip install --upgrade numpy
# RUN pip install --upgrade scipy
RUN pip install --upgrade pymc
RUN pip install --upgrade scikit-learn
# RUN pip install git+https://github.com/njsmith/scikits-sparse.git
# RUN pip install git+https://github.com/pymc-devs/pymc
RUN pip install --upgrade git+https://github.com/Theano/Theano.git
RUN pip install --upgrade statsmodels
# RUN pip install --upgrade git+https://github.com/statsmodels/statsmodels.git
# RUN pip install --upgrade git+https://github.com/scikit-learn/scikit-learn.git
RUN pip install --upgrade seaborn
RUN pip install --upgrade rpy2
RUN pip install terminado

# RUN pip3 install --upgrade numpy
# RUN pip3 install --upgrade scipy
RUN pip install --upgrade pymc
RUN pip3 install --upgrade scikit-learn
# RUN pip3 install git+https://github.com/njsmith/scikits-sparse.git
# RUN pip3 install git+https://github.com/pymc-devs/pymc
RUN pip3 install --upgrade git+https://github.com/Theano/Theano.git
RUN pip3 install --upgrade statsmodels
# RUN pip3 install --upgrade git+https://github.com/statsmodels/statsmodels.git
# RUN pip3 install --upgrade git+https://github.com/scikit-learn/scikit-learn.git
# RUN pip3 install --upgrade seaborn # why does this fail on Python 3?
RUN pip3 install --upgrade rpy2
RUN pip3 install terminado

RUN R -e 'source("http://bioconductor.org/biocLite.R"); biocLite("edgeR"); biocLite("DESeq2"); biocLite("DESeq");'

RUN mkdir -p /srv/

# install jupyterhub
ADD requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

ADD configurable-http-proxy /tmp/configurable-http-proxy
WORKDIR /tmp/configurable-http-proxy
RUN npm install -g

WORKDIR /srv/
ADD . /srv/jupyterhub
WORKDIR /srv/jupyterhub/

RUN pip3 install .

WORKDIR /srv/jupyterhub/

# Derivative containers should add jupyterhub config,
# which will be used when starting the application.

EXPOSE 8000

VOLUME /notebooks

# ONBUILD ADD jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py
# CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
ENTRYPOINT ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
