terraform {
    source = "git::https://github.com/pimsmath/k8s-syzygy-aks.git"
}

include {
    path = find_in_parent_folders()
}

inputs = {
   prefix    = "jhub"
   location  = "canadacentral"
}
