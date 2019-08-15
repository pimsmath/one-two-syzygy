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
