FROM debian@sha256:f7062cf040f67f0c26ff46b3b44fe036c29468a7e69d8170f37c57f2eec1261b
# 2016-05-03 debian image
MAINTAINER Enrique Cornejo "enrique@cornejo.me"

# USER root
# RUN apt-get update && sudo apt-get upgrade -y
# RUN apt-get install -y git wget bzip2   \
#     build-essential python-dev gfortran \
#     gdal-bin libgdal-dev
# # Hacky, but if not GDAL complains --there's got to be a
# # better solution.
# RUN ln -s /opt/conda/lib/libjpeg.so.9 /opt/conda/lib/libjpeg.so.8
# RUN ldconfig
# RUN conda install -y gdal
# RUN echo $(python --version)

# Environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NB_USER vizzuality
ENV NB_UID 1000
ENV HOME /home/$NB_USER
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8


USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)

# RUN echo "deb $REPO/debian jessie main\ndeb $REPO/debian-security jessie/updates main" > /etc/apt/sources.list
RUN apt-get update && apt-get -yq dist-upgrade		\
    && apt-get install -yq --no-install-recommends	\
    wget         					\
    build-essential					\
    bzip2						\
    ca-certificates					\
    sudo						\
    locales						\
    # libav is needed to animate matplolib stuff
    libav-tools 					\
    && apt-get clean                                    \
    && rm -rf /var/lib/apt/lists/*

# Generate the locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen &&       \
    locale-gen

# Let's install a basic data science environment

# Tini
ENV TINI_VERSION v0.14.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini
RUN chmod +x /usr/local/bin/tini
ENTRYPOINT ["/usr/local/bin/tini", "--"]

# Create jovyan user with UID=1000 and in the 'users' group
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER $CONDA_DIR

USER $NB_USER

# Setup vizzuality home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

# Install the latest conda as vizzuality
RUN cd /tmp &&										\
    mkdir -p $CONDA_DIR &&								\
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh &&	\
    /bin/bash Miniconda3-latest-Linux-x86_64.sh -f -b -p $CONDA_DIR &&			\
    rm Miniconda3-latest-Linux-x86_64.sh &&						\
    $CONDA_DIR/bin/conda config --system --add channels conda-forge &&			\
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false &&		\
    conda install --quiet --yes -n root conda-build &&						\
    conda clean -tipsy

# Install Jupyter Notebook and Hub
RUN conda install --quiet --yes \
    'notebook=4.3*'		\
    jupyterhub=0.7		\
    && conda clean -tipsy

# Install Python 3 packages

COPY conda_requirements.txt .
RUN conda install --quiet --yes $(cat conda_requirements.txt) &&	\
    conda remove --quiet --yes --force qt pyqt &&			\
    conda clean -tipsy

RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix

USER root

EXPOSE 8888
WORKDIR /home/$NB_USER/work

# Configure container startup
ENTRYPOINT ["/usr/local/bin/tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
# COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_USER