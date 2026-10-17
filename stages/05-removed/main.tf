terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

module "app" {
  source = "./modules/app"

  directory = "${path.root}/out"
}

resource "terraform_data" "registry" {
  input = "v1"
}

# local_file.legacy resource block deleted from the config. Without this block Terraform
# would destroy the file; with destroy = false it only forgets it (Terraform 1.7+).
removed {
  from = local_file.legacy

  lifecycle {
    destroy = false
  }
}
