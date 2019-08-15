# One-Two-Syzygy

This repository contains materials for setting up a kubernetes based
[Syzygy](https://syzygy.ca) instance. There this is some terraform/terragrunt
code in [./infrastructure](./infrastructure) to define a cluster (on AWS for
now) then there is a helm chart in [./one-two-syzygy](./one-two-syzygy) to
configure the syzygy instance.

The one-two-syzygy helm chart is a thin wrapper around the [zero-to-jupyterhub
(z2jh)](https://github.com/jupyterhub/zero-to-jupyterhub) chart ( installed as a
dependency). It includes a shibboleth service provider(SP)/proxy which allows a
customized hub image to use shibboleth for authentication.
[Chartpress](https://github.com/jupyterhub/chartpress) is used to manage the
helm repository and the necessary images: 

  * [hub](./images/hub): A minor modification of the z2jh hub image to include a
    remote-user authenticator
  * [shib](./images/shib): A shibboleth-sp proxy

The intention for this project is that it should be able to run on any cloud
provider, but do-date only AWS is tested.  [pull
requests](https://github.com/pimsmath/one-two-syzygy/pulls) and
[suggestions](https://github.com/pimsmath/one-two-syzygy/issues) for this (and
any other enhancements) are very welcome.


## Usage

## Terraform/Terragrunt

Terraform code to define a kubernetes cluster is kept in the
[syzygy-k8s](https://github.com/pimsmath/syzygy-k8s.git) repository, from which
we create instances using
[terragrunt](https://github.com/gruntwork-io/terragrunt).

New instances are created by defining a `terragrunt.hcl` in a new directory of
[./infrastructure/terraform/prod/](./infrastructure/terraform/prod):
```hcl
# ./infrastructure/terraform/prod/example
terraform {
    source = "git::https://github.com/pimsmath/syzygy-k8s.git//?ref=v0.1.1"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   region  = "us-west-2"
   profile = "iana"
}
```

This files references
[./infrastructure/prod/terragrunt.hcl](./infrastructure/prod/terragrunt.hcl)
which defines an s3 bucket to hold the tfstate file. This should be customized
to use an s3 bucket you control.

```bash
$ terragrunt init
$ terragrunt apply
```

The output of `terragrunt apply` (or `terragrunt output`) includes the
filesystem ID for the [EFS Filesystem](https://aws.amazon.com/efs/) which was
created. This ID value will be needed by helm below.


Use the AWS-CLI to update your `~/.kube/config` with the authentication details
of your new cluster

```bash
$ aws --profile=iana --region=us-west-2 eks list-clusters
...
{
    "clusters": [
        "syzygy-eks-tJSxgQlx"
    ]
}

$ aws --profile=iana --region=us-west-2 eks update-kubeconfig \
  --name=syzygy-eks-tJSxgQlx
```

And check that you can interact with the cluster
```bash
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.3", GitCommit:"5e53fd6bc17c0dec8434817e69b04a25d8ae0ff0", GitTreeState:"clean", BuildDate:"2019-06-06T01:44:30Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"13+", GitVersion:"v1.13.8-eks-a977ba", GitCommit:"a977bab148535ec195f12edc8720913c7b943f9c", GitTreeState:"clean", BuildDate:"2019-07-29T20:47:04Z", GoVersion:"go1.11.5", Compiler:"gc", Platform:"linux/amd64"}

$ kubectl get nodes
NAME                                       STATUS   ROLES    AGE     VERSION
ip-10-1-1-224.us-west-2.compute.internal   Ready    <none>   8m29s   v1.13.7-eks-c57ff8
ip-10-1-2-85.us-west-2.compute.internal    Ready    <none>   8m48s   v1.13.7-eks-c57ff8
ip-10-1-3-122.us-west-2.compute.internal   Ready    <none>   8m30s   v1.13.7-eks-c57ff8
```

If you don't see any worker nodes you may need to check your AWS IAM role
configuration.

## Helm
Install the latest release of [Helm](https://helm.sh/). We will be using RBAC
(see the [helm RBAC
documentation](https://helm.sh/docs/using_helm/#role-based-access-control)), so
we need to configure a role for tiller and initialize tiller. A sample
[rbac-config.yaml](./one-two-syzygy/infrastructure/yaml/rbac-config.yaml) is
included, but you may need to configure it to suit your needs.  

```bash
$ kubectl create -f docs/rbac-config.yaml
$ helm init --service-account tiller --history-max 200
```

After a few minutes check the helm and tiller versions
```bash
$ helm version
Client: &version.Version{SemVer:"v2.14.2", GitCommit:"a8b13cc5ab6a7dbef0a58f5061bcc7c0c61598e7", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.14.2", GitCommit:"a8b13cc5ab6a7dbef0a58f5061bcc7c0c61598e7", GitTreeState:"clean"}
```


## One-Two-Syzygy

Create a config.yaml at the root of this repository. A sample configuration file
is included as [./config.yaml.sample](./config.yaml.sample).

### z2jh options 

See the [z2jh configuration
documentation](https://zero-to-jupyterhub.readthedocs.io/en/latest/reference.html).
Since z2jh is a dependency of this chart, remember to wrap then in a jupyterhub
block inside `config.yaml`. e.g.

```yaml
jupyterhub:
  proxy:
    secretToken: "output of `openssl rand -hex 32`"
  service:
    type: ClusterIP
```

### efs-provisioner options
See the
[efs-provisioner](https://github.com/helm/charts/tree/master/stable/efs-provisioner)
chart for details
```yaml
efs-provisioner:
  efsProvisioner:
    efsFileSystemId: fs-0000000
    awsRegion: us-west-2
```

### one-two-syzygy options
For the one-two-syzygy chart you will need

 * **shib.acm.arn**: The ARN of your ACM certificate as a string
 * **shib.spcert**: The plain text of your SP certificate
 * **shib.spkey**: The plain text of your SP key


For the shibboleth configuration (shibboleth2.xml, attribute-map.xml and
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
