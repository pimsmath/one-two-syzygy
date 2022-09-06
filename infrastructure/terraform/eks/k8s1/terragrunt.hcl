terraform {
    #source = "git::https://github.com/pimsmath/k8s-syzygy-eks.git//?ref=v1.0.0"
    source = "../../../../../terraform-modules//k8s-syzygy-eks/"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   region  = "ca-central-1"
   profile = "default"

   worker_group_user_node_type = "m5.large"
   worker_group_min_size = 0
   worker_group_max_size = 4
   worker_group_desired_capacity = 1

   tags = {
       Project = "syzygy-eks"
       Class   = "k8s1"
   }

   map_users = [
   {
       userarn  = "arn:aws:iam::830114512327:user/iana-admin"
       username = "iana-admin"
       groups   = ["system:masters"]
   }]
}
