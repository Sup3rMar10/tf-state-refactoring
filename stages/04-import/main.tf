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

resource "local_file" "legacy" {
  filename = "${path.root}/out/legacy.txt"
  content  = "legacy file"
}

resource "terraform_data" "registry" {
  input = "v1"
}

# demo.sh deleted terraform_data.registry from state (as if state were lost or the object
# had been created by hand). The object still exists; this block adopts it back.
import {
  to = terraform_data.registry
  id = "REGISTRY_ID"
}
