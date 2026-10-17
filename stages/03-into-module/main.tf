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

# Keep the earlier moved block too: anyone whose state is still at the old address
# gets migrated step by step. Chains of moves are followed.
moved {
  from = local_file.config
  to   = local_file.app_config
}

moved {
  from = local_file.app_config
  to   = module.app.local_file.config
}

resource "local_file" "legacy" {
  filename = "${path.root}/out/legacy.txt"
  content  = "legacy file"
}

resource "terraform_data" "registry" {
  input = "v1"
}
