FROM unicon/shibboleth-sp

RUN yum -y update \
    && yum -y install php mod_ssl   

COPY var-www-html/ /var/www/html/
