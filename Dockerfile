FROM debian:jessie

MAINTAINER https://github.com/NII-cloud-operation

ENV DEBIAN_FRONTEND noninteractive
RUN REPO=http://cdn-fastly.deb.debian.org \
 && echo "deb $REPO/debian jessie main\ndeb $REPO/debian-security jessie/updates main" > /etc/apt/sources.list \
 && apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    build-essential \
    curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen


# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Create 'bit_kun' user
ENV NB_USER bit_kun
ENV NB_UID 1000
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir /home/$NB_USER/.jupyter && \
    chown -R $NB_USER:users /home/$NB_USER/.jupyter && \
    echo "$NB_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$NB_USER

# Install Jupyter

### environments for Python3
ENV CONDA3_DIR /opt/conda3
RUN cd /tmp && \
    mkdir -p $CONDA3_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.5.4-Linux-x86_64.sh && \
    echo "a946ea1d0c4a642ddf0c3a26a18bb16d *Miniconda3-4.5.4-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-4.5.4-Linux-x86_64.sh -f -b -p $CONDA3_DIR && \
    rm Miniconda3-4.5.4-Linux-x86_64.sh && \
    $CONDA3_DIR/bin/conda config --system --add channels conda-forge && \
    $CONDA3_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA3_DIR/bin/conda update --all --quiet --yes && \
    $CONDA3_DIR/bin/conda install --quiet --yes \
    notebook matplotlib pandas pip && \
    $CONDA3_DIR/bin/pip --no-cache-dir install pytz && \
    $CONDA3_DIR/bin/conda clean -tipsy
ENV PATH=$CONDA3_DIR/bin:$PATH

## Python kernel with matplotlib, etc...
RUN pip --no-cache-dir install jupyter && \
    pip --no-cache-dir install pandas matplotlib numpy \
                seaborn scipy scikit-learn dill bokeh && \
    apt-get update && apt-get install -yq --no-install-recommends \
    git \
    vim \
    jed \
    emacs \
    unzip \
    libsm6 \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    libxrender1 \
    inkscape \
    wget \
    curl \
    fonts-ipafont-gothic fonts-ipafont-mincho \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy config files
ADD conf /tmp/
RUN mkdir -p /etc/jupyter && \
    cp -f /tmp/jupyter_notebook_config.py \
       /etc/jupyter/jupyter_notebook_config.py

SHELL ["/bin/bash", "-c"]

### ansible
RUN apt-get update && \
    apt-get -y install sshpass openssl ipmitool libssl-dev libffi-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    pip --no-cache-dir install requests paramiko ansible

### Utilities
RUN apt-get update && apt-get install -y virtinst dnsutils zip tree jq && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    pip --no-cache-dir install netaddr pyapi-gitlab runipy \
                pysnmp pysnmp-mibs

### Add files
RUN mkdir -p /etc/ansible && cp /tmp/ansible.cfg /etc/ansible/ansible.cfg

#### Visualization
RUN pip --no-cache-dir install folium

### extensions for jupyter
#### jupyter_nbextensions_configurator
#### jupyter_contrib_nbextensions
#### Jupyter-LC_nblineage (NII) - https://github.com/NII-cloud-operation/Jupyter-LC_nblineage
#### Jupyter-LC_through (NII) - https://github.com/NII-cloud-operation/Jupyter-LC_run_through
#### Jupyter-LC_wrapper (NII) - https://github.com/NII-cloud-operation/Jupyter-LC_wrapper
#### Jupyter-multi_outputs (NII) - https://github.com/NII-cloud-operation/Jupyter-multi_outputs
#### Jupyter-LC_index (NII) - https://github.com/NII-cloud-operation/Jupyter-LC_index
RUN pip --no-cache-dir install jupyter_nbextensions_configurator && \
    pip --no-cache-dir install six bash_kernel \
    https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master \
    https://github.com/NII-cloud-operation/Jupyter-LC_nblineage/tarball/master \
    https://github.com/NII-cloud-operation/Jupyter-LC_run_through/tarball/master \
    https://github.com/NII-cloud-operation/Jupyter-LC_wrapper/tarball/master \
    git+https://github.com/NII-cloud-operation/Jupyter-multi_outputs \
    git+https://github.com/NII-cloud-operation/Jupyter-LC_index.git \
    git+https://github.com/NII-cloud-operation/Jupyter-LC_notebook_diff.git

RUN jupyter contrib nbextension install && \
    jupyter nblineage quick-setup && \
    jupyter run-through quick-setup && \
    jupyter nbextension install --py lc_multi_outputs && \
    jupyter nbextension enable --py lc_multi_outputs && \
    jupyter nbextension install --py notebook_index && \
    jupyter nbextension enable --py notebook_index && \
    jupyter nbextension install --py lc_wrapper && \
    jupyter nbextension enable --py lc_wrapper && \
    jupyter nbextension install --py lc_notebook_diff && \
    python -m bash_kernel.install && \
    jupyter kernelspec install /tmp/kernels/python3-wrapper && \
    jupyter kernelspec install /tmp/kernels/bash-wrapper

### notebooks dir
RUN mkdir -p /notebooks
ADD sample-notebooks /notebooks
RUN chown $NB_USER:users -R /notebooks
WORKDIR /notebooks

### utilities
RUN pip install papermill

### Bash Strict Mode
RUN cp /tmp/bash_env /etc/bash_env
ENV BASH_ENV=/etc/bash_env

### nbconfig
RUN mkdir -p /etc/jupyter/nbconfig && \
    cp /tmp/notebook.json /etc/jupyter/nbconfig/notebook.json && \
    cp /tmp/tree.json /etc/jupyter/nbconfig/tree.json

### Theme for jupyter
ENV CUSTOM_DIR=$CONDA3_DIR/lib/python3.7/site-packages/notebook/static/custom
RUN mkdir -p $CUSTOM_DIR && \
    cp /tmp/custom.css $CUSTOM_DIR/custom.css && \
    cp /tmp/logo.png $CUSTOM_DIR/logo.png && \
    mkdir -p $CUSTOM_DIR/codemirror/addon/merge/ && \
    curl -fL https://raw.githubusercontent.com/cytoscape/cytoscape.js/master/dist/cytoscape.min.js > $CUSTOM_DIR/cytoscape.min.js && \
    curl -fL https://raw.githubusercontent.com/iVis-at-Bilkent/cytoscape.js-view-utilities/master/cytoscape-view-utilities.js > $CUSTOM_DIR/cytoscape-view-utilities.js && \
    curl -fL https://raw.githubusercontent.com/NII-cloud-operation/Jupyter-LC_notebook_diff/master/html/jupyter-notebook-diff.js > $CUSTOM_DIR/jupyter-notebook-diff.js && \
    curl -fL https://raw.githubusercontent.com/NII-cloud-operation/Jupyter-LC_notebook_diff/master/html/jupyter-notebook-diff.css > $CUSTOM_DIR/jupyter-notebook-diff.css && \
    curl -fL https://cdnjs.cloudflare.com/ajax/libs/diff_match_patch/20121119/diff_match_patch.js > $CUSTOM_DIR/diff_match_patch.js && \
    curl -fL https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.35.0/addon/merge/merge.js > $CUSTOM_DIR/codemirror/addon/merge/merge.js && \
    curl -fL https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.35.0/addon/merge/merge.min.css > $CUSTOM_DIR/merge.min.css

### Custom get_ipython().system() to control error propagation of shell commands
RUN mkdir -p /etc/ipython/profile_default/startup && \
    cp /tmp/10-custom-get_ipython_system.py /etc/ipython/profile_default/startup/
USER $NB_USER

ENV SHELL=/bin/bash
ENTRYPOINT ["tini", "--"]
CMD ["jupyter", "notebook"]
