# One-Two-Syzygy

This repository contains the materials for setting up a kubernetes based syzygy
instance. Mostly this is some terraform code to define a cluster (somewhere, AWS
for now) followed by a thin wrapper around the
[zero-to-jupyterhub](https://github.com/jupyterhub/zero-to-jupyterhub) helm
chart.  We install z2jh as a dependency of the one-two-syzygy chart which also
includes a shibboleth service provider which can be used to add shibboleth as an
authentication option. The helm chart portions of this repository use
[chartpress](https://github.com/jupyterhub/chartpress) utility to create two
images

  * [hub](./images/hub): A minor modification of the z2jh hub image to include a
    remote-user authenticator
  * [shib](./images/shib): A shibboleth-sp proxy

The intention for this project is to be able to run on any cloud provider, but
do-date only AWS is configured. 
[pull requests](https://github.com/pimsmath/one-two-syzygy/pulls) and
[suggestions](https://github.com/pimsmath/one-two-syzygy/issues) for this (and
any other enhancements) are very welcome.


## Usage

## Terraform/Terragrunt

The terraform code defining our kubernetes cluster is kept in
the [syzygy-k8s](https://github.com/pimsmath/syzygy-k8s.git) repository.
Instances are created by terragrunt by defining a `terragrunt.hcl` file in the
[./infrastructure/terraform/prod/](./infrastructure/terraform/prod) directory,
e.g.
```hcl
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

The file included above defines an s3 bucket where terragrunt can store the
tfstate file, customize it to suit your needs.

```bash
$ terragrunt init
$ terragrunt apply
```
The output of apply (or `terragrunt output`) includes the filesystem ID of the
EFS Filesystem created, make a note of this, you will need to pass it as a
configuration variable to helm.

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

If you don't see any worker nodes, check the AWS IAM role configuration.

## Helm
Install the latest release of [Helm](https://helm.sh/). We will be using RBAC
(see the [helm RBAC
documentation](https://helm.sh/docs/using_helm/#role-based-access-control), so
we need to configure a role for tiller and initialize tiller. A sample
[rbac-config.yaml](./one-two-syzygy/infrastructure/yaml/rbac-config.yaml) is
included, but configure this to suit your needs.  

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

Create a config.yaml at the root of this repository. For the most part you just
need to specify whichever [z2jh
options](https://zero-to-jupyterhub.readthedocs.io/en/latest/reference.html)
options you want, but since z2jh is a dependency of this chart, remember to wrap
then in a jupyterhub block inside `config.yaml`. e.g.

```yaml
jupyterhub:
  proxy:
    secretToken: "See the z2jh repository for instructions"
  service:
    type: ClusterIP
```

Similarly you will need to specify

 * **efs-provisioner.efsProvisioner.efsFileSystemId**: The FSID of the EFS that
   was created by terragrunt (e.g. fs-0b0740a9)

For the efs-provisioner dependency.

For the one-two-syzygy chart you will need

 * **shib.acm.arn**: The ARN of your ACM certificate as a string
 * **shib.spcert**: The plain text of your SP certificate
 * **shib.spkey**: The plain text of your SP key

A sample configuration file is included as
[./config.yaml.sample](./config.yaml.sample).

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
