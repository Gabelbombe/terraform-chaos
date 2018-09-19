variable "profile" {
  type    = "string"
  default = "default"
}

variable "region" {
  type    = "string"
  default = "us-west-2"
}

variable "vpc_cidr" {
  type    = "string"
  default = "172.16.0.0/16"
}

variable "team_name" {
  type    = "string"
  default = "testing"
}

variable "ami_id" {
  type    = "string"
  default = ""
}

variable "instance_type" {
  type    = "string"
  default = "t2.nano"
}

variable "ssh_keyname" {
  type = "string"
}
