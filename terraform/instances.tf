
resource "aws_launch_configuration" "django-launch-config" {
  name_prefix          = "django-launch-config"
  image_id             = "${var.AWS_AMI}"
  instance_type        = "${var.AWS_INATANCE}"
  key_name             = "${var.KEY_NAME}"
  security_groups      = ["${aws_security_group.ssh_ping.id}","${aws_security_group.website.id}"]
  user_data=<<-EOF
  #!/bin/bash
  sudo echo -n "wai=" > /etc/environment
  sudo curl http://169.254.169.254/latest/meta-data/instance-id >> /etc/environment
  source /etc/environment
  echo $wai
  sudo systemctl start docker
  git clone https://github.com/silui/zero-downtime-CI-CD-deployment.git
  cd zero-downtime-CI-CD-deployment/cowork_space
  sudo docker-compose up -d --build
  EOF
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"
  lifecycle              { create_before_destroy = true }
}

resource "aws_autoscaling_group" "example-autoscaling" {
  name                 = "example-autoscaling"
  vpc_zone_identifier  = ["${aws_subnet.public_us1a.id}"]
  launch_configuration = "${aws_launch_configuration.django-launch-config.name}"
  min_size             = 2
  max_size             = 8
  desired_capacity     = 2
  termination_policies = ["NewestInstance"]
  health_check_grace_period = 100
  health_check_type = "ELB"
  load_balancers = ["${aws_elb.stupid-elb.name}"]
  force_delete = true

  tags = [{
      key = "Name"
      value = "ec2 instance"
      propagate_at_launch = true
  },
  {
      key = "Production"
      value = "true"
      propagate_at_launch = true
  },
  ]
}

resource "aws_instance" "jenkins_server" {
  ami           = "ami-05611ae044b2c20ef"
  instance_type = "t2.medium"
  subnet_id = "${aws_subnet.public_us1a.id}"
  key_name = "Edward-IAM-keypair"
  vpc_security_group_ids = ["${aws_security_group.ssh_ping.id}","${aws_security_group.website.id}"]
  user_data=<<-EOF
  #!/bin/bash
  sudo systemctl start docker
  sudo usermod -a -G docker ec2-user
  sudo service jenkins start
  sudo gpasswd -a jenkins docker
  EOF
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"
tags{
    Name = "jenkins-server"
 }
}

resource "aws_eip" "lb" {
  instance = "${aws_instance.jenkins_server.id}"
  vpc      = true
}
resource "aws_iam_role_policy_attachment" "instance_profile_codedeploy" {
  role       = "${aws_iam_role.instance_profile.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

#---------a bunch of privilage nonsence starts here------------
#instance security group
resource "aws_security_group" "ssh_ping" {
  vpc_id = "${aws_vpc.main.id}"
  name = "ssh_ping"
  description = "security group that allows incoming ssh and ping. allow all outgoing traffics"
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    }

tags {
    Name = "ssh_ping"
  }
}

resource "aws_security_group" "website"{
    vpc_id = "${aws_vpc.main.id}"
    name = "website"
    description = "enable for web server communication"
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        from_port = 80
        to_port = 80
        protocol="tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        from_port = 8080
        to_port = 8080
        protocol="tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        from_port = 8000
        to_port = 8000
        protocol="tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags{Name="website"}
}


resource "aws_security_group" "elb-securitygroup" {
  vpc_id = "${aws_vpc.main.id}"
  name = "elb"
  description = "security group for load balancer"
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "elb_sg"
  }
}
