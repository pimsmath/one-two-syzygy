FROM jupyterhub/k8s-hub:0.11.1

USER root

ADD requirements.txt /tmp/requirements.txt

RUN PYCURL_SSL_LIBRARY=openssl \
    pip install --no-cache-dir \
        -r /tmp/requirements.txt

USER ${NB_USER}
