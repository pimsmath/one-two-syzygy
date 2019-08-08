# one-two-syzygy

This repository contains the Helm charts for the "next steps" after
[zero-to-jupyterhub](https://github.com/jupyterhub/zero-to-jupyterhub).
Basically it wraps that chart up with a shibboleth service provider which can be
used to add shibboleth as an authentication option. It uses the [chartpress]
utility to create two images

  * hub: A minor modification of the z2jh hub image to include a remote-user
    authenticator
  * shib: A shibboleth sp proxy

Most of the development for this chart has taken place on AWS but the components
are ultimately intended to be provider agnostic. PRs and suggestions for this
(and any other enhancements are very welcome).

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

 * shib.acm.arn: The ARN of your ACM certificate as a string
 * shib.spcert: The plaintext of your SP certificate
 * shib.spkey: The plaintext of your SP key

The shibboleth configuration (shibboleth2.xml, attribute-map.xml and
idp-metadata.xml) are populated from a configmap, via the following keys

 * shib.shibboleth2xml
 * shib.idpmetadataxml
 * shib.attributemapxml

To avoid problems with string formatting, it is usually easiest to place the
relevant files in a directory called `./files` then include them via the
`--set-file` argument to helm, e.g.

```bash
$ helm upgrade --wait --install --namespace=syzygy syzygy one-two-syzygy \
  --values=one-two-syzygy/values.yaml -f config.yaml
  --set-file "shub.shibboleth2xml=./files/shibboleth2.xml"
  --set-file "shib.idpmetadataxml=./files/idp-metadata.xml"
  --set-file "shib.attributemapxml=./files/attribute-map.xml"
  --tls
```

## Helm Repository
Releases of this chart are published to the
[gh-pages](https://pimsmath.github.io/one-two-syzygy) which serves as a Helm
repository via chartpress.
