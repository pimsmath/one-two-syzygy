terraform {
    #source = "git::https://github.com/pimsmath/k8s-syzygy-eks.git//?ref=v0.3.0"
    source = "../../../../../k8s-syzygy-eks"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   region  = "ca-central-1"
   profile = "default"

   #worker_group_user_node_type = "m5.2xlarge"
   worker_group_user_asg_min_size = 1
   worker_group_user_asg_max_size = 3
   worker_group_user_asg_desired_capacity = 1

   map_users = [
   {
       userarn  = "arn:aws:iam::830114512327:user/iana"
       username = "iana"
       groups   = ["system:masters"]
   }]
}
