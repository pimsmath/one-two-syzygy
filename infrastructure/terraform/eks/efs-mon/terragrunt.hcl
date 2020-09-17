terraform {
    source = "git::https://github.com/pimsmath/efs-mon//?ref=v0.1.3"
    #source = "/Users/iana/efs-mon"
}

include {
    path = find_in_parent_folders()
}


inputs = {
   region               = "ca-central-1"
   profile              = "default"
   remote_state_bucket  = "syzygy-infrastructure-k8s"
   remote_state_key     = "eks/k8s1/terraform.tfstate"
   ssh_key              = "AWS_admin"
}
