#Azure location
variable "location"{
    default = "westus2"
    type = string
}

#Customer Name - Prefix
variable "customer_name" {
  default = "isuru"
  type = string
}

variable "environment" {
  default = "prd"
  type = string
}