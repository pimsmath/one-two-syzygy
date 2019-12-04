remote_state {
    backend = "s3"
    config  = {
        encrypt        = true
        region         = "ca-central-1"
        bucket         = "syzygy-infrastructure-k8s"
        key            = "${path_relative_to_include()}/terraform.tfstate"
        dynamodb_table = "terraform-locks"
    }
}

terraform {
    extra_arguments "bucket" {
        commands = get_terraform_commands_that_need_vars()
    }
}
