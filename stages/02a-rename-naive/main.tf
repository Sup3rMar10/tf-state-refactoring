terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Renamed local_file.config -> local_file.app_config WITHOUT a moved block.
# Terraform sees "config" gone and "app_config" new: destroy + create.
resource "local_file" "app_config" {
  filename = "${path.root}/out/app.txt"
  content  = "app config v1"
}

resource "local_file" "legacy" {
  filename = "${path.root}/out/legacy.txt"
  content  = "legacy file"
}

resource "terraform_data" "registry" {
  input = "v1"
}
