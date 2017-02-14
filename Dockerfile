FROM jupyter/datascience-notebook
MAINTAINER Enrique Cornejo "enrique@cornejo.me"


ENV DEBIAN_FRONTEND noninteractive
USER root
RUN apt-get update && sudo apt-get upgrade -y
RUN apt-get install -y git wget bzip2   \
    build-essential python-dev gfortran \
    gdal-bin libgdal-dev
RUN apt-get clean
# Hacky, but if not GDAL complains --there's got to be a
# better solution.
RUN ln -s /opt/conda/lib/libjpeg.so.9 /opt/conda/lib/libjpeg.so.8
RUN ldconfig

USER jovyan
WORKDIR /home/jovyan/work
RUN conda install -y gdal
RUN echo $(python --version)
