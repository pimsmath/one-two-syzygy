# One-Two-Syzygy

This repository contains the Helm charts for the "next steps" after
[zero-to-jupyterhub](https://github.com/jupyterhub/zero-to-jupyterhub).
Basically it wraps that chart together with a shibboleth service provider which
can be used to add shibboleth as an authentication option. It uses the
[chartpress](https://github.com/jupyterhub/chartpress) utility to create two
images

  * [hub](./images/hub): A minor modification of the z2jh hub image to include a
    remote-user authenticator
  * [shib](./images/shib): A shibboleth-sp proxy

Most of the development for this chart has taken place on AWS but the components
are ultimately intended to be provider agnostic (anywhere kubernetes runs).  To
that point, [pull requests](https://github.com/pimsmath/one-two-syzygy/pulls)
and [suggestions](https://github.com/pimsmath/one-two-syzygy/issues) for this
(and any other enhancements) are very welcome.


## Instructions

You will probably want a `config.yaml` containing mostly of the same options
as you would for the z2jh chart, just remember that you will need to put the
keys one level deeper than normal, inside a jupyterhub key, e.g.

```yaml
jupyterhub:
  proxy:
    secretToken: "See the z2jh repository for instructions"
  service:
    type: ClusterIP
```

In addition to the z2jh configuration you will need to specify the SP
configuration via a `config.yaml` file in this directory as follows

 * **shib.acm.arn**: The ARN of your ACM certificate as a string
 * **shib.spcert**: The plain text of your SP certificate
 * **shib.spkey**: The plain text of your SP key

The shibboleth configuration (shibboleth2.xml, attribute-map.xml and
idp-metadata.xml) are populated from a ConfigMap, via the following keys

 * shib.shibboleth2xml
 * shib.idpmetadataxml
 * shib.attributemapxml

To avoid problems with string formatting, it is usually easiest to place the
relevant files in a directory called `./files` then include them via the
`--set-file` argument to helm, e.g.

```bash
$ helm upgrade --wait --install --namespace=syzygy syzygy one-two-syzygy \
  --values=one-two-syzygy/values.yaml -f config.yaml
  --set-file "shib.shibboleth2xml=./files/shibboleth2.xml"
  --set-file "shib.idpmetadataxml=./files/idp-metadata.xml"
  --set-file "shib.attributemapxml=./files/attribute-map.xml"
  --tls
```

## Development
Try the instructions for
[z2jh](https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/master/CONTRIBUTING.md).
If you already have a kubernetes cluster up and running you should only need
```bash
$ python3 -m venv .
$ source bin/activate
$ python3 -m pip install -r dev-requirements.txt
```
When you make changes in the images or templates directory, commit them and run
chart press

```bash
# To build new images and update Chart.yaml/values.yaml tags
$ chartpress

# To push tagged images to Dockerhub
$ chartpress --push

# To publish the repository to our helm repository
$ chartpress --publish
```

## Helm Repository
Releases of this chart are published to the
[gh-pages](https://pimsmath.github.io/one-two-syzygy) which serves as a Helm
repository via chartpress.
