resource "aws_iam_instance_profile" "simian_army_profile" {
  name = "simian_army_profile"
  role = "${aws_iam_role.simian_army_role.name}"
}

data "aws_iam_policy_document" "simian_army" {
  statement {
    sid    = "ChaosAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals = {
      type = "AWS"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "simian_army_role" {
  name               = "simian_army_role"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.simian_army.json}"
}

resource "aws_security_group" "simian_army_instance" {
  name   = "Allow chaos monkey to connect to internet"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name_prefix}simian-army-instance-sg"
  }
}

resource "aws_iam_role_policy_attachment" "simian_army_role_ec2_full_access" {
  role       = "${aws_iam_role.simian_army_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_instance" "simian_army" {
  subnet_id                   = "${var.subnet_id}"
  ami                         = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.ssh_keyname}"
  user_data                   = "${data.template_file.user_data.rendered}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.simian_army_profile.id}"
  vpc_security_group_ids      = ["${aws_security_group.sshaccess.id}", "${aws_security_group.simian_army_instance.id}"]

  tags {
    Name = "${var.name_prefix}monkey_of_chaos"
  }

  lifecycle {
    create_before_destroy = true
  }
}
