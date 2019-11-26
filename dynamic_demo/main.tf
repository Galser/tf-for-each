resource "random_pet" "cattles" {
  length    = 3
  separator = ","
}

locals {
  pets_list = split(",", random_pet.cattles.id)
}

resource "null_resource" "echo" {
  for_each = toset(local.pets_list)

  triggers = {
    time = "${each.value}-${timestamp()}"
  }

  provisioner "local-exec" {
    command = "echo ${each.value}"
  }
}