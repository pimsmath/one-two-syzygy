terraform {
    source = "git::https://github.com/pimsmath/k8s-syzygy-eks.git//?ref=v0.4.0"
    #source = "../../../../../terraform-modules//k8s-syzygy-eks/"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   region  = "ca-central-1"
   profile = "iana"

   worker_group_user_node_type = "t2.medium"
   worker_group_user_asg_min_size = 1
   worker_group_user_asg_max_size = 4
   worker_group_user_asg_desired_capacity = 1

   map_users = [
   {
       userarn  = "arn:aws:iam::830114512327:user/iana"
       username = "iana"
       groups   = ["system:masters"]
   }]
}
