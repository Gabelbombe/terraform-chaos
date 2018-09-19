resource "aws_security_group" "instance_sg" {
  name   = "Allow ELB access to instance"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port       = 8080
    protocol        = "tcp"
    to_port         = 8080
    security_groups = ["${aws_security_group.elb_sg.id}"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.team_name}-ehime-instance-sg"
  }
}

resource "aws_security_group" "elb_sg" {
  name   = "Allow public access via http"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.team_name}-ehime-elb-sg"
  }
}

data "template_file" "ehime_userdata" {
  template = "${file("${path.module}/templates/ehime-userdata.tpl")}"
}

resource "aws_launch_configuration" "ehime_lc" {
  name_prefix                 = "${var.team_name}-"
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.ssh_keyname}"
  user_data                   = "${data.template_file.ehime_userdata.rendered}"
  security_groups             = ["${aws_security_group.instance_sg.id}"]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name_prefix               = "${var.team_name}-"
  launch_configuration      = "${aws_launch_configuration.ehime_lc.id}"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = ["${aws_subnet.public_subnets.*.id}"]
  load_balancers            = ["${aws_elb.elb.id}"]
  health_check_type         = "ELB"
  health_check_grace_period = 120
  wait_for_capacity_timeout = "3m"

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.team_name}-ehime"
      propagate_at_launch = true
    },
  ]
}

resource "aws_elb" "elb" {
  name            = "${var.team_name}-ehime-elb"
  subnets         = ["${aws_subnet.public_subnets.*.id}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    interval            = 5
    target              = "HTTP:8080/status"
    timeout             = 2
    unhealthy_threshold = 2
  }
}
