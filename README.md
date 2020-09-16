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
provider, but to-date only AWS/EKS and AKS tested.  [pull
requests](https://github.com/pimsmath/one-two-syzygy/pulls) and
[suggestions](https://github.com/pimsmath/one-two-syzygy/issues) for this (and
any other enhancements) are very welcome.


## Usage

## Terraform/Terragrunt

Terraform code to define a kubernetes cluster is kept in provider specific
repositories for now: 
[aws/eks](https://github.com/pimsmath/syzygy-k8s-eks.git), [microsoft/aks](https://github.com/pimsmath/syzygy-k8s-aks.git) .

We create instances using
[terragrunt](https://github.com/gruntwork-io/terragrunt).

### EKS

New instances are created by defining a `terragrunt.hcl` in a new directory of
[./infrastructure/terraform/prod/](./infrastructure/terraform/prod):
```hcl
# ./infrastructure/terraform/prod/eks/k8s1
terraform {
    source = "git::https://github.com/pimsmath/syzygy-k8s-eks.git//?ref=v0.3.1"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   region  = "ca-central-1"
   profile = "iana"
   # Additional users who should be able to control the cluster
   # map_users = [ {} ]
}
```

This files references
[./infrastructure/prod/terragrunt.hcl](./infrastructure/prod/terragrunt.hcl)
which defines an s3 bucket to hold the tfstate file. This should be customized
to use an s3 bucket you control. Before `apply`-ing, check the configuration of
your `worker_group` configuration in the corresponding [terraform
module](https://github.com/pimsmath/k8s-syzygy-eks). A typical configuration
includes a group with labels and taints to make sure that only user pods are
run.

```bash
$ terragrunt init
$ terragrunt apply
```

For EKS, the output of `terragrunt apply` (or `terragrunt output`) includes the
cluster name and the filesystem ID for the [EFS
Filesystem](https://aws.amazon.com/efs/) which was created. Both of these values
will needed by helm below.


Use the AWS-CLI to update your `~/.kube/config` with the authentication details
of your new cluster

```bash
$ aws --profile=iana --region=ca-central-1 eks list-clusters
...
{
    "clusters": [
        "syzygy-eks-qiGa7B01"
    ]
}

$ aws --profile=iana --region=ca-central-1 eks update-kubeconfig \
  --name=syzygy-eks-qiGa7B01
```

### AKS

New instances are created by defining a `terragrunt.hcl` in a new directory of
[./infrastructure/terraform/prod/](./infrastructure/terraform/prod):
```hcl
# ./infrastructure/terraform/prod/aks/k8s2
terraform {
    source = "git::https://github.com/pimsmath/k8s-syzygy-aks.git"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   prefix    = "jhub"
   location  = "canadacentral"
}
```
This files references
[./infrastructure/prod/terragrunt.hcl](./infrastructure/prod/terragrunt.hcl)
which defines an s3 bucket to hold the tfstate file. This should be customized
to use an s3 bucket you control.

You will also need to define a few variables:
```bash
mv infrastructure/terraform/aks/k8s2/env.auto.tfvars.json.dist infrastructure/terraform/aks/k8s2/env.auto.tfvars.json
```
Edit the file `infrastructure/terraform/aks/k8s2/env.auto.tfvars.json` and fill in the missing variables. See `https://github.com/pimsmath/k8s-syzygy-aks/blob/master/README.md` for details on how to find out those variables.

```bash
$ terragrunt init
$ terragrunt apply
```
Once the above commands complete successfully, you can setup the new credential for kubectl config.
```bash
# to get resourc group and name of the cluster
az aks list
az aks get-credentials --resource-group RESOURCE_GROUP --name CLUSTER_NAME
```

## K8S Cluster

Once the K8S cluster is provisioned, check that you can interact with the cluster
```bash
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"19", GitVersion:"v1.19.0", GitCommit:"e19964183377d0ec2052d1f1fa930c4d7575bd50", GitTreeState:"clean", BuildDate:"2020-08-26T21:54:15Z", GoVersion:"go1.15", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"17+", GitVersion:"v1.17.9-eks-4c6976", GitCommit:"4c6976793196d70bc5cd29d56ce5440c9473648e", GitTreeState:"clean", BuildDate:"2020-07-17T18:46:04Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}

$ kubectl get nodes
NAME                                       STATUS   ROLES    AGE     VERSION
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-1-1-165.ca-central-1.compute.internal   Ready    <none>   18m   v1.17.9-eks-4c6976
ip-10-1-1-178.ca-central-1.compute.internal   Ready    <none>   18m   v1.17.9-eks-4c6976
ip-10-1-2-178.ca-central-1.compute.internal   Ready    <none>   18m   v1.17.9-eks-4c6976
```

If you don't see any worker nodes you may need to check your AWS IAM role
configuration.

## Helm
Install the latest release of [Helm](https://helm.sh/).
```bash
$ helm version
version.BuildInfo{Version:"v3.3.0", GitCommit:"8a4aeec08d67a7b84472007529e8097ec3742105", GitTreeState:"dirty", GoVersion:"go1.14.6"}
```


## One-Two-Syzygy

Create a config.yaml at the root of this repository. A sample configuration file
is included as [./config.yaml.sample](./config.yaml.sample). There are two
dependent charts we will need
([zero-to-jupyterhub](https://jupyterhub.github.io/helm-chart) and
[efs-provisioner](https://kubernetes-charts.storage.googleapis.com/).
```bash
$ helm dependency update
```

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

For AWS we currently deploy the autoscaler as a separate component, so
```yaml
$ helm install cluster-autoscaler --namespace kube-system \
  stable/cluster-autoscaler --values=autoscaler.yaml
```

For the one-two-syzygy chart you will need

 * **shib.acm.arn**: The ARN of your ACM certificate as a string
 * **shib.spcert**: The plain text of your SP certificate
 * **shib.spkey**: The plain text of your SP key


For the shibboleth configuration you will need some configuration from the
identity provider. Typically you can specify the service configuration with the
following 3 files: `shibboleth2.xml`, `attribute-map.xml` and
`idp-metadata.xml`. These are included for the sp deployment as a ConfigMap with
the following keys

 * shib.shibboleth2xml
 * shib.idpmetadataxml
 * shib.attributemapxml

Helm will look for these in `one-two-syzygy/files/etc/shibboleth/` and they can
be overridden with the usual helm tricks (`--set-file` or config.yaml). Default
values are given but these are specific to the UBC IdP so you **almost certainly
will want to override them**. 

The apache configuration for the sp is given as another ConfigMap with the keys
being the apache config files usually kept under `/etc/httpd/conf.d/*.conf`. The
actual web content can be specified as a ConfigMap (with structure corresponding
to the `conf.d/*.conf` files).

```bash
$ kubectl create namespace syzygy
$ helm upgrade --cleanup-on-fail --wait --install syzygy one-two-syzygy \
  --namespace syzygy --create-namespace -f config.yaml
```

If everything has worked, you can extract the address of the public SP with
```bash
$ kubectl -n syzygy get svc/sp
```

Depending on your provider this may be a DNS entry or an IP address and you will
need to populate it to your DNS service.

When you are done with the cluster and ready to recover the resources, you will want to do something like (**N.B. This may delete all files, including user data!**)
```bash
$ cd one-two-syzygy
$ helm --namespace=syzygy del syzygy

$ cd infrastructure/terraform/eks/k8s1
$ terragrunt destroy
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

If you want to make local modifications to the underlying terraform code, you
can feed these to terragrunt via the "--terragrunt-source" option. There are
some subtleties when doing this, but something like this should work if you have
your modules in e.g. `~/terraform-modules/k8s-syzygy-eks`
```bash
  $ terragrunt apply
  --terragrunt-source=../../../../../terraform-modules//k8s-syzygy-eks
```

## Helm Repository
Releases of this chart are published to the
[gh-pages](https://pimsmath.github.io/one-two-syzygy) which serves as a Helm
repository via chartpress.


## Tear Down

To tear everything down, run the following command:
```bash
terragrunt destroy-all
```
