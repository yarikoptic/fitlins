# Generated by Neurodocker v0.3.2.
#
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
#     https://github.com/kaczmarj/neurodocker
#
# Timestamp: 2018-05-22 20:52:23

FROM neurodebian@sha256:5fbbad8c68525b588a459092254094436aae9dc1f3920f8d871a03053b10377c

ARG DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------
# Install common dependencies and create default entrypoint
#----------------------------------------------------------
ENV LANG="en_US.UTF-8" \
    LC_ALL="C.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN apt-get update -qq && apt-get install -yq --no-install-recommends  \
    	apt-utils bzip2 ca-certificates curl locales unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && localedef --force --inputfile=en_US --charmap=UTF-8 C.UTF-8 \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> $ND_ENTRYPOINT \
         && echo 'set +x' >> $ND_ENTRYPOINT \
         && echo 'if [ -z "$*" ]; then /usr/bin/env bash; else $*; fi' >> $ND_ENTRYPOINT; \
       fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker
ENTRYPOINT ["/neurodocker/startup.sh"]

LABEL maintainer="Christopher J. Markiewicz"

ARG PYTHON_VERSION_MAJOR="3"
ARG PYTHON_VERSION_MINOR="6"
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ENV MKL_NUM_THREADS="1" \
    OMP_NUM_THREADS="1"

# Create new user: neuro
RUN useradd --no-user-group --create-home --shell /bin/bash neuro
USER neuro

#------------------
# Install Miniconda
#------------------
ENV CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:$PATH
RUN echo "Downloading Miniconda installer ..." \
    && miniconda_installer=/tmp/miniconda.sh \
    && curl -sSL --retry 5 -o $miniconda_installer https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && /bin/bash $miniconda_installer -b -p $CONDA_DIR \
    && rm -f $miniconda_installer \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    && conda update -n base conda \
    && conda clean -tipsy && sync

#-------------------------
# Create conda environment
#-------------------------
RUN conda create -y -q --name neuro python=${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} \
                                    icu=58.1 \
                                    mkl=2018.0.1 \
                                    mkl-service \
                                    git=2.9.3 \
    && sync && conda clean -tipsy && sync \
    && sed -i '$isource activate neuro' $ND_ENTRYPOINT

#-------------------------
# Update conda environment
#-------------------------
RUN conda install -y -q --name neuro numpy=1.14.1 \
                                     scipy=1.0.0 \
                                     scikit-learn=0.19.1 \
                                     matplotlib=2.1.2 \
                                     seaborn=0.8.1 \
                                     pytables=3.4.2 \
                                     pandas=0.22.0 \
                                     nipype=1.0.3 \
                                     patsy \
    && sync && conda clean -tipsy && sync

COPY [".", "/src/fitlins"]

# User-defined instruction
RUN echo "$VERSION" > /src/fitlins/fitlins/VERSION

USER root

# User-defined instruction
RUN mkdir /work && chown -R neuro /src /work

USER neuro

#-------------------------
# Update conda environment
#-------------------------
RUN /bin/bash -c "source activate neuro \
      && pip install -q --no-cache-dir -r /src/fitlins/requirements.txt" \
    && sync

#-------------------------
# Update conda environment
#-------------------------
RUN /bin/bash -c "source activate neuro \
      && pip install -q --no-cache-dir -e /src/fitlins[all]" \
    && sync

WORKDIR /work

ENTRYPOINT ["/neurodocker/startup.sh", "fitlins"]

LABEL org.label-schema.build-date="$BUILD_DATE" \
      org.label-schema.name="FitLins" \
      org.label-schema.description="FitLins - Fit Linear Models to BIDS datasets" \
      org.label-schema.url="http://github.com/poldracklab/fitlins" \
      org.label-schema.vcs-ref="$VCS_REF" \
      org.label-schema.vcs-url="https://github.com/poldracklab/fitlins" \
      org.label-schema.version="$VERSION" \
      org.label-schema.schema-version="1.0"

#--------------------------------------
# Save container specifications to JSON
#--------------------------------------
RUN echo '{ \
    \n  "pkg_manager": "apt", \
    \n  "check_urls": false, \
    \n  "instructions": [ \
    \n    [ \
    \n      "base", \
    \n      "neurodebian@sha256:5fbbad8c68525b588a459092254094436aae9dc1f3920f8d871a03053b10377c" \
    \n    ], \
    \n    [ \
    \n      "label", \
    \n      { \
    \n        "maintainer": "Christopher J. Markiewicz" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "arg", \
    \n      { \
    \n        "PYTHON_VERSION_MAJOR": "3", \
    \n        "PYTHON_VERSION_MINOR": "6", \
    \n        "BUILD_DATE": "", \
    \n        "VCS_REF": "", \
    \n        "VERSION": "" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "env", \
    \n      { \
    \n        "MKL_NUM_THREADS": "1", \
    \n        "OMP_NUM_THREADS": "1" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "neuro" \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "env_name": "neuro", \
    \n        "activate": true, \
    \n        "conda_install": "python=${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} icu=58.1 mkl=2018.0.1 mkl-service git=2.9.3" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "env_name": "neuro", \
    \n        "conda_install": "numpy=1.14.1 scipy=1.0.0 scikit-learn=0.19.1 matplotlib=2.1.2 seaborn=0.8.1 pytables=3.4.2 pandas=0.22.0 nipype=1.0.3 patsy" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "copy", \
    \n      [ \
    \n        ".", \
    \n        "/src/fitlins" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "echo \"$VERSION\" > /src/fitlins/fitlins/VERSION" \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "root" \
    \n    ], \
    \n    [ \
    \n      "run", \
    \n      "mkdir /work && chown -R neuro /src /work" \
    \n    ], \
    \n    [ \
    \n      "user", \
    \n      "neuro" \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "env_name": "neuro", \
    \n        "pip_opts": "-r", \
    \n        "pip_install": "/src/fitlins/requirements.txt" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "miniconda", \
    \n      { \
    \n        "env_name": "neuro", \
    \n        "pip_opts": "-e", \
    \n        "pip_install": "/src/fitlins[all]" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "workdir", \
    \n      "/work" \
    \n    ], \
    \n    [ \
    \n      "entrypoint", \
    \n      "/neurodocker/startup.sh fitlins" \
    \n    ], \
    \n    [ \
    \n      "label", \
    \n      { \
    \n        "org.label-schema.build-date": "$BUILD_DATE", \
    \n        "org.label-schema.name": "FitLins", \
    \n        "org.label-schema.description": "FitLins - Fit Linear Models to BIDS datasets", \
    \n        "org.label-schema.url": "http://github.com/poldracklab/fitlins", \
    \n        "org.label-schema.vcs-ref": "$VCS_REF", \
    \n        "org.label-schema.vcs-url": "https://github.com/poldracklab/fitlins", \
    \n        "org.label-schema.version": "$VERSION", \
    \n        "org.label-schema.schema-version": "1.0" \
    \n      } \
    \n    ] \
    \n  ], \
    \n  "generation_timestamp": "2018-05-22 20:52:23", \
    \n  "neurodocker_version": "0.3.2" \
    \n}' > /neurodocker/neurodocker_specs.json
