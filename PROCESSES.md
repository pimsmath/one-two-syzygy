# Deployment Processes

# Table of Contents

* [Deploying z2jh/efs](#deploy-z2jh-efs)

## Deploying z2jh with EFS
The process for deploying z2jh using EFS as persistent user storage is similar
to deploying one-two-syzygy. In fact, the steps are identical up until we start
interacting with helm so please see the [main README.md](./README.md) for
details. We pick up from there, assuming you have a functioning kubernetes
cluster and an efs called `fs-071eb8ea`.

```bash
kubectl create namespace syzygy
```

Create a config file for the
[efs-provisioner
chart](https://github.com/helm/charts/tree/master/stable/efs-provisioner).
Specifically, tell the chart your fs-id (check `terragrunt output` if you're not
sure)
```yaml
efsProvisioner:
  efsProvisionerName: example.com/aws-efs
  efsFileSystemId: fs-071eb98ea
  awsRegion: ca-central-1
```

Apply this chart and check that the provisioner pod shows up in the expected
namespace.
```bash
$ helm upgrade --wait --install --namespace=syzygy efs stable/efs-provisioner \
  --create-namespace --values=efs-config.yaml 
$ kubectl -n syzygy get pods
NAME                                   READY   STATUS    RESTARTS   AGE
efs-efs-provisioner-68d7b8cb57-rh45s   1/1     Running   0          39m
```

If you are intending to use autoscaling, deploy that chart to the kube-system
namespace
```bash
$ helm upgrade --wait --install --namespace=kube-system cluster-autoscaler \
  stable/cluster-autoscaler --namespace=kube-system --values=autoscaler.yaml
```

Next deploy zero-to-jupyterhub with a config which points towards the efs
storageclass
```bash
debug:
  enabled: true

cull:
  enabled: true
  users: false
  timeout: 3600
  every: 600
  concurrency: 10
  maxAge: 0

proxy:
  secretToken: <REPLACE WITH THE OUTPUT OF openssl rand -hex 32>
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: <REPLACE WITH THE ARN OF A VALID CERT>
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "3600"
  https:
    enabled: true
    type: offload

singleuser:
  storage:
    dynamic:
      storageClass: aws-efs
      storageProvisioner: 
```

Deploy this as well
```bash
$ helm upgrade --wait --install --namespace=syzygy efs jupyterhub/jupyterhub \
  --version=0.8.2 --values=efs-config.yaml
```

Get the endpoint of the LoadBalancer and create an CNAME if you like
```bash
$ kubectl -n syzygy get svc/proxy-public \
  -o custom-columns=DNS:.status.loadBalancer.ingress[0].hostname
DNS
a763024f33ca711eaa32d02196b8bba5-1124919000.ca-central-1.elb.amazonaws.com
```
I created a `CNAME` [k8s1.syzygy.farm](https://k8s1.syzygy.ca) domain with this
as the value. The certificate I used in the load balancer specification also
holds this name.

## Hubtraf
Clone out hubtraf and install it
```bash
$ git clone https://github.com/yuvipanda/hubtraf
$ cd hubtraf
$ pip3.6 install -e .
```

Test this against the new z2jh instance
```bash
$ hubtraf --json --user-session-min-runtime 10 \
  --user-session-max-runtime 30 \
  --user-session-max-start-delay 5 https://k8s1.syzygy.farm 10
```
This should simulate 10 users logging in and doing nothing for a few seconds
before vanishing.

## Examining User Storage
Create an EC2 instance in the same VPC as the kubernetes cluster and install the
EFS/NFS tools. Replace $VPC as needed.
```bash
$ aws ec2 create-security-group --group-name SSH \
  --description "Global SSH Access" --vpc-id $VPC
{
    "GroupId": "sg-064cec64bf9f253e1"
}

$ aws ec2 authorize-security-group-ingress \
  --group-id sg-064cec64bf9f253e1 --protocol tcp \
  --port 22 --cidr 0.0.0.0/0

$ aws ec2 run-instances --image-id ami-0a269ca7cc3e3beff \
  --count 1 --instance-type t2.micro --key-name AWS_admin \
  --security-group-ids sg-064cec64bf9f253e1 \
  --subnet-id subnet-04c761c1c8c480029 \
  --associate-public-ip-address
```

Once the instance is available ssh in, install the efs tools and mount the
EFS filesystem. From here you should be able to examine anything created by the
efs-provisioner.
```bash
  # Find the remote address of your instance with something like
  # $instanceID=$(aws ec2 describe-instances --instance-ids $instanceId \
    --query 'Reservations[0].Instances[0].PublicDnsName' \
    --output text)
  $ ssh ec2-user -l $instanceID
  $ sudo yum install amazon-efs-utils
  $ sudo mkdir /mnt/efs
  $ sudo mount -t efs fs-071eb8ea:/ /mnt/efs
```

When you're done, remember that these resources were defined _outside_ of
terraform so you should delete them before expecting terraform to tidy up the
rest. A nice solution would be to define this in terraform/terragrunt as a
separate project.
```bash
aws ec2 terminate-instance --instance-id i-XXXXXXXXXXXXXXXXX
aws ec2 deauthorize-security-group-ingress --group-id sg-064cec64bf9f253e1 \
  --protocol tcp --port 22 --cidr 0.0.0.0
aws ec2 delete-security-group --group-id sg-064cec64bf9f253e1
```

