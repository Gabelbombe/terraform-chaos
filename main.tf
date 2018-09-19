provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_availability_zones" "current" {}

module "simian_army" {
  source      = "modules/simian-army"
  ami_id      = "${data.aws_ami.ubuntu.id}"
  sshkeyname  = "${var.sshkeyname}"
  name_prefix = "${var.team_name}-"
  subnet_id   = "${element(aws_subnet.public_subnets.*.id, 0)}"
  vpc_id      = "${aws_vpc.vpc.id}"

  # Example config:
  # Unleash the monkey to attack ASGs once every minute with 50% chance
  calendar_ismonkeytime = "true"

  chaos_leashed           = "true"
  chaos_asg_enabled       = "true"
  scheduler_frequency     = "1"
  scheduler_frequencyunit = "MINUTES"
  chaos_asg_probability   = "180.0"
}
