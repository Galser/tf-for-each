# tf-for-each
Sample repo, Terraform, [for-each](https://www.terraform.io/docs/configuration/resources.html#for_each-multiple-resource-instances-defined-by-a-map-or-set-of-strings) meta-argument


# **for_each**: Multiple Resource Instances Defined By a Map, or Set of Strings

By default, a resource block configures one real infrastructure object. However, sometimes you want to manage several similar objects, such as a fixed pool of compute instances. Terraform has two ways to do this: ``count`` and ``for_each``. 

The ``for_each`` meta-argument accepts a map or a set of strings, and creates an instance for each item in that map or set. Each instance has a distinct infrastructure object associated with it , and each is separately created, updated, or destroyed when the configuration is applied.

## ``count`` and ``for_each`` distinction

If your resource instances are almost identical, ``count`` is appropriate. If some of their arguments need distinct values that can't be directly derived from an integer, it's safer to use ``for_each``.

## Referencing iterated individual objects, via ``each``
In resource blocks where ``for_each`` is set, an additional each object is available in expressions, so you can modify the configuration of each instance. This object has two attributes:

- **each.key** — The map key (or set member) corresponding to this instance.
- **each.value** — The map value corresponding to this instance. (*If a set was provided, this is the same as each.key.*)


# Example of usage

Consider following example inspired by farm animals : 
```terraform
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

  provisioner "local-exec"  {
    command = "echo ${each.value}"
  }
}
```
It will create three individual instancs of the ``null_resoruce`` and when applied produce following results : 
```bash
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # null_resource.echo["chicken"] will be created
  + resource "null_resource" "echo" {
      + id       = (known after apply)
      + triggers = {
          + "time" = "is fried"
        }
    }

  # null_resource.echo["duck"] will be created
  + resource "null_resource" "echo" {
      + id       = (known after apply)
      + triggers = {
          + "time" = "is roasted"
        }
    }

  # null_resource.echo["pony"] will be created
  + resource "null_resource" "echo" {
      + id       = (known after apply)
      + triggers = {
          + "time" = "constantly eats"
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

null_resource.echo["pony"]: Creating...
null_resource.echo["duck"]: Creating...
null_resource.echo["chicken"]: Creating...
null_resource.echo["chicken"]: Provisioning with 'local-exec'...
null_resource.echo["duck"]: Provisioning with 'local-exec'...
null_resource.echo["pony"]: Provisioning with 'local-exec'...
null_resource.echo["duck"] (local-exec): Executing: ["/bin/sh" "-c" "echo is roasted"]
null_resource.echo["pony"] (local-exec): Executing: ["/bin/sh" "-c" "echo constantly eats"]
null_resource.echo["chicken"] (local-exec): Executing: ["/bin/sh" "-c" "echo is fried"]
null_resource.echo["chicken"] (local-exec): is fried
null_resource.echo["duck"] (local-exec): is roasted
null_resource.echo["pony"] (local-exec): constantly eats
null_resource.echo["chicken"]: Creation complete after 0s [id=1345602464036277363]
null_resource.echo["duck"]: Creation complete after 0s [id=7599475383745773099]
null_resource.echo["pony"]: Creation complete after 0s [id=1826639553216774122]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```
Where you can clearly see that one description of the ``null_resource`` had produced creation of three distinctive instances, each with unique local provisioner and name.

## Referring to individual Instances of resources
When ``for_each`` is set, Terraform distinguishes between the resource block itself and the multiple **resource instances** associated with it. Instances are identified by a map key (or set member) from the value provided to for_each.

- <TYPE>.<NAME> (for example, `null_resource.echo` ) refers to the resource block.
- <TYPE>.<NAME>[<KEY>] (for example, `null_resource.echo["chicken"]`,`null_resource.echo["pony"]` , etc.) refers to individual instances.
This is different from resources without `count` or `for_each`, which can be referenced without an index or key.

> Note: Within nested provisioner or connection blocks, the special self object refers to the current resource instance, not the resource block as a whole.

## Sets 

The Terraform language doesn't have a literal syntax for sets, but you can use the ``toset`` function to convert a list of strings to a set. In such case `each.key` and `each.value` would be equal

## Using (*computed*) Expressions in for_each

The `for_each` meta-argument accepts map or set [expressions](https://www.terraform.io/docs/configuration/expressions.html). However, unlike most resource arguments, the `for_each` value must be known before Terraform performs any remote resource actions. This means `for_each` **can't refer to any resource attributes that aren't known until after a configuration is applied** (such as a unique ID generated by the remote API when an object is created).

The `for_each` value must be a map or set with one element per desired resource instance. If you need to declare resource instances based on a nested data structure or combinations of elements from multiple data structures you can use Terraform expressions and functions to derive a suitable value.

For some common examples of such situations, see the [flatten](https://www.terraform.io/docs/configuration/functions/flatten.html) and [setproduct](https://www.terraform.io/docs/configuration/functions/setproduct.html) functions.


### Example for the sets and computed expressions 

Well, now we want to have a little bit more random farm, considering not only of animals, but inhabitants also named by some epithets, in the best style of Salvador Dali.  

Create following code ( it is provided or your convinence in the [/dynamic_demo](/dynamic_demo) folder ) :

```terraform
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
```
As we dealing with dynamic resource, this example also going to demo the fact that values for the `for_each` should be known before apply of resource with this meta-argument. So we going to apply our configuration in several steps

- Step 1 : Plan **random** resources 
PLan creation ONLY of the random pet names by executing :  
`terraform plan -out make_farm.plan -target random_pet.cattles` :
Output : 
```bash

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # random_pet.cattles will be created
  + resource "random_pet" "cattles" {
      + id        = (known after apply)
      + length    = 3
      + separator = ","
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Warning: Resource targeting is in effect

You are creating a plan with the -target option, which means that the result
of this plan may not represent all of the changes requested by the current
configuration.

The -target option is not for routine use, and is provided only for
exceptional situations such as recovering from errors or mistakes, or when
Terraform specifically suggests to use it as part of an error message.


------------------------------------------------------------------------

This plan was saved to: make_farm.plan

To perform exactly these actions, run the following command to apply:
    terraform apply "make_farm.plan"
``` 
- Step 2 : Create random resources with apply of the plan
Execute `terraform apply make_farm.plan`
Output : 
```bash
terraform apply make_farm.plan
random_pet.cattles: Creating...
random_pet.cattles: Creation complete after 0s [id=scarcely,closing,macaque]

Warning: Applied changes may be incomplete

The plan was created with the -target option in effect, so some changes
requested in the configuration may have been ignored and the output values may
not be fully updated. Run the following command to verify that no other
changes are pending:
    terraform plan

Note that the -target option is not suitable for routine use, and is provided
only for exceptional situations such as recovering from errors or mistakes, or
when Terraform specifically suggests to use it as part of an error message.


Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```
- Step 3, apply the rest , creating several ``random_resources```
Execute : `terraform apply` :
```bash
random_pet.cattles: Refreshing state... [id=scarcely,closing,macaque]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # null_resource.echo["closing"] will be created
  + resource "null_resource" "echo" {
      + id       = (known after apply)
      + triggers = (known after apply)
    }

  # null_resource.echo["macaque"] will be created
  + resource "null_resource" "echo" {
      + id       = (known after apply)
      + triggers = (known after apply)
    }

  # null_resource.echo["scarcely"] will be created
  + resource "null_resource" "echo" {
      + id       = (known after apply)
      + triggers = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

null_resource.echo["closing"]: Creating...
null_resource.echo["macaque"]: Creating...
null_resource.echo["scarcely"]: Creating...
null_resource.echo["macaque"]: Provisioning with 'local-exec'...
null_resource.echo["scarcely"]: Provisioning with 'local-exec'...
null_resource.echo["closing"]: Provisioning with 'local-exec'...
null_resource.echo["scarcely"] (local-exec): Executing: ["/bin/sh" "-c" "echo scarcely"]
null_resource.echo["macaque"] (local-exec): Executing: ["/bin/sh" "-c" "echo macaque"]
null_resource.echo["closing"] (local-exec): Executing: ["/bin/sh" "-c" "echo closing"]
null_resource.echo["scarcely"] (local-exec): scarcely
null_resource.echo["scarcely"]: Creation complete after 0s [id=2898971486049243919]
null_resource.echo["macaque"] (local-exec): macaque
null_resource.echo["closing"] (local-exec): closing
null_resource.echo["macaque"]: Creation complete after 0s [id=5918004633495761018]
null_resource.echo["closing"]: Creation complete after 0s [id=2442632657723353184]
```
Here you go, we have 3 resorurces created using `for_eachz from one resrouce declaration : 
```terraform 
null_resource.echo["closing"]: Creating...
null_resource.echo["macaque"]: Creating...
null_resource.echo["scarcely"]: Creating...
```



# TODO


# DONE
- [x] make demo code
- [x] create readme