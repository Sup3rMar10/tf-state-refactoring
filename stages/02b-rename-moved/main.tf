terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "app_config" {
  filename = "${path.root}/out/app.txt"
  content  = "app config v1"
}

# Same rename, but declared: the object in state is re-addressed, nothing is recreated.
moved {
  from = local_file.config
  to   = local_file.app_config
}

resource "local_file" "legacy" {
  filename = "${path.root}/out/legacy.txt"
  content  = "legacy file"
}

resource "terraform_data" "registry" {
  input = "v1"
}
