terraform {
    source = "git::https://github.com/pimsmath/k8s-syzygy-eks.git//?ref=v0.2.5"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   region  = "ca-central-1"
   profile = "default"
   map_users = [
   {
       userarn  = "arn:aws:iam::544539453627:user/iana"
       username = "ckrzysik"
       groups   = ["system:masters"]
   },
   {
       userarn  = "arn:aws:iam::876123132216:root"
       username = "root"
       groups   = ["system:masters"]
   }]
}
