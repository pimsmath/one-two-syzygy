FROM jupyterub/k8s-hub

ARG JUPYTERHUB_VERSION=1.0.*

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG HOME=/home/jovyan

ADD requirements.txt /tmp/requirements.txt
RUN PYCURL_SSL_LIBRARY=openssl pip3 install --no-cache-dir \
         -r /tmp/requirements.txt \
         $(bash -c 'if [[ $JUPYTERHUB_VERSION == "git"* ]]; then \
            echo ${JUPYTERHUB_VERSION}; \
          else \
            echo jupyterhub==${JUPYTERHUB_VERSION}; \
          fi')

USER ${NB_USER}
