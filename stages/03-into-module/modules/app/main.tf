terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

variable "directory" {
  type = string
}

resource "local_file" "config" {
  filename = "${var.directory}/app.txt"
  content  = "app config v1"
}
