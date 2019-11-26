variable "pets_activity_list" {
  default = {
    "duck" : "is roasted",
    "chicken" : "is fried",
    "pony" : "constantly eats"
  }
}

resource "null_resource" "echo" {
  for_each = var.pets_activity_list

  triggers = {
    time = "${each.value}"
  }

  provisioner "local-exec" {
    command = "echo ${each.value}"
  }
}
