You'll generally want 3 files in this directory to configure the shibboleth-sp

  * shibboleth2.xml
  * attribute-map.xml
  * idp-metadata.xml

These are then passed to helm with the `--set-file` option, e.g.
```bash
  helm upgrade --install ...
    --set-file "shib.shibboleth2xml=./files/shibboleth2.xml" \
    --set-file "shib.attributemapxml=./files/attribute-map.xml" \
    --set-file "shib.idpmetadataxml=./files/idp-metadata.xml"
```
