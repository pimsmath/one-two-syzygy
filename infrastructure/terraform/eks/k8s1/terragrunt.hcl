terraform {
    source = "git::https://github.com/pimsmath/k8s-syzygy-eks.git//?ref=v0.2.4"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   region  = "ca-central-1"
   profile = "iana"
   map_users = [
   {
       userarn  = "arn:aws:iam::830114512327:user/iana"
       username = "iana"
       groups   = ["system:masters"]
   },
   {
       userarn  = "arn:aws:iam::830114512327:user/ckrzysik"
       username = "ckrzysik"
       groups   = ["system:masters"]
   }]
}
