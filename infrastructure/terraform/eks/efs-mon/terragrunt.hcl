terraform {
    source = "git::https://github.com/pimsmath/efs-mon//?ref=v0.1.2"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   region     = "ca-central-1"
   profile    = "default"
   vpc_id     = "vpc-0ad3f397d51cc46bf"
   subnet_id  = "subnet-0e7bc66efee3f18bd"
   ssh_key    = "AWS_admin"
}
