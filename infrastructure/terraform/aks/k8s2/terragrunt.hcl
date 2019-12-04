terraform {
    source = "git::https://github.com/pimsmath/syzygy-k8s.git//?ref=azure"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   prefix    = "jhub"
   location  = "canadacentral"
}
