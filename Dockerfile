FROM jupyter/minimal-notebook

MAINTAINER https://github.com/NII-cloud-operation
USER root

# Create 'bit_kun' user
ENV NB_USER bit_kun
ENV NB_UID 1001
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir /home/$NB_USER/.jupyter && \
    chown -R $NB_USER:users /home/$NB_USER/.jupyter && \
    echo "$NB_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$NB_USER

## Python kernel with matplotlib, etc...
RUN apt-get update && apt-get install -yq --no-install-recommends \
    git \
    vim \
    jed \
    emacs \
    unzip \
    wget \
    curl \
    fonts-ipafont-gothic fonts-ipafont-mincho \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy config files
ADD conf /tmp/
USER $NB_USER
RUN mkdir -p $HOME/.jupyter && \
    cp -f /tmp/jupyter_notebook_config.py \
       $HOME/.jupyter/jupyter_notebook_config.py

USER root

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

### Visualization
RUN pip --no-cache-dir install folium

### extensions for Jupyter (python3)
#### jupyter_nbextensions_configurator
#### jupyter_contrib_nbextensions
#### Jupyter-LC_nblineage (NII) - https://github.com/NII-cloud-operation/Jupyter-LC_nblineage
#### Jupyter-LC_through (NII) - https://github.com/NII-cloud-operation/Jupyter-LC_run_through
#### Jupyter-LC_wrapper (NII) - https://github.com/NII-cloud-operation/Jupyter-LC_wrapper
#### Jupyter-multi_outputs (NII) - https://github.com/NII-cloud-operation/Jupyter-multi_outputs
#### Jupyter-LC_index (NII) - https://github.com/NII-cloud-operation/Jupyter-LC_index
RUN pip --no-cache-dir install jupyter_nbextensions_configurator \
    https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master \
    https://github.com/NII-cloud-operation/Jupyter-LC_nblineage/tarball/master \
    https://github.com/NII-cloud-operation/Jupyter-LC_run_through/tarball/master \
    https://github.com/NII-cloud-operation/Jupyter-LC_wrapper/tarball/master \
    git+https://github.com/NII-cloud-operation/Jupyter-multi_outputs \
    git+https://github.com/NII-cloud-operation/Jupyter-LC_index.git \
    git+https://github.com/NII-cloud-operation/Jupyter-LC_notebook_diff.git


USER $NB_USER
RUN mkdir -p $HOME/.local/share && \
    jupyter contrib nbextension install --user && \
    jupyter nblineage quick-setup --user && \
    jupyter run-through quick-setup --user && \
    jupyter nbextension install --py lc_multi_outputs --user && \
    jupyter nbextension enable --py lc_multi_outputs --user && \
    jupyter nbextension install --py notebook_index --user && \
    jupyter nbextension enable --py notebook_index --user && \
    jupyter nbextension install --py lc_wrapper --user && \
    jupyter nbextension enable --py lc_wrapper --user && \
    jupyter nbextension install --py lc_notebook_diff --user && \
    jupyter kernelspec install /tmp/kernels/python3-wrapper --user

### notebooks dir
USER root
RUN mkdir -p /notebooks
ADD sample-notebooks /notebooks
RUN chown $NB_USER:users -R /notebooks
WORKDIR /notebooks

### utilities
RUN pip --no-cache-dir install papermill

### Bash Strict Mode
RUN cp /tmp/bash_env /etc/bash_env
ENV BASH_ENV=/etc/bash_env

### nbconfig
USER $NB_USER
RUN mkdir -p $HOME/.jupyter/nbconfig && \
    cp /tmp/notebook.json $HOME/.jupyter/nbconfig/notebook.json

### Theme for jupyter
RUN mkdir -p $HOME/.jupyter/custom/ && \
    cp /tmp/custom.css $HOME/.jupyter/custom/custom.css && \
    cp /tmp/logo.png $HOME/.jupyter/custom/logo.png && \
    mkdir -p $HOME/.jupyter/custom/codemirror/addon/merge/ && \
    curl -fL https://raw.githubusercontent.com/cytoscape/cytoscape.js/master/dist/cytoscape.min.js > $HOME/.jupyter/custom/cytoscape.min.js && \
    curl -fL https://raw.githubusercontent.com/iVis-at-Bilkent/cytoscape.js-view-utilities/master/cytoscape-view-utilities.js > $HOME/.jupyter/custom/cytoscape-view-utilities.js && \
    curl -fL https://raw.githubusercontent.com/NII-cloud-operation/Jupyter-LC_notebook_diff/master/html/jupyter-notebook-diff.js > $HOME/.jupyter/custom/jupyter-notebook-diff.js && \
    curl -fL https://raw.githubusercontent.com/NII-cloud-operation/Jupyter-LC_notebook_diff/master/html/jupyter-notebook-diff.css > $HOME/.jupyter/custom/jupyter-notebook-diff.css && \
    curl -fL https://cdnjs.cloudflare.com/ajax/libs/diff_match_patch/20121119/diff_match_patch.js > $HOME/.jupyter/custom/diff_match_patch.js && \
    curl -fL https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.35.0/addon/merge/merge.js > $HOME/.jupyter/custom/codemirror/addon/merge/merge.js && \
    curl -fL https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.35.0/addon/merge/merge.min.css > $HOME/.jupyter/custom/merge.min.css

### Custom get_ipython().system() to control error propagation of shell commands
RUN mkdir -p $HOME/.ipython/profile_default/startup && \
    cp /tmp/10-custom-get_ipython_system.py $HOME/.ipython/profile_default/startup/

ENV SHELL=/bin/bash
