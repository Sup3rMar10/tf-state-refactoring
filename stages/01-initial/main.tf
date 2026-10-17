terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "config" {
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
