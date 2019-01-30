provider "aws" { 
    region = "${var.AWS_REGION}"
}

resource "aws_launch_configuration" "example-launchconfig" {
  name_prefix          = "example-launchconfig"
  image_id             = "ami-08c3fac0de21367fc"
  instance_type        = "t2.medium"
  key_name             = "Edward-IAM-keypair"
  security_groups      = ["${aws_security_group.ssh_ping.id}","${aws_security_group.website.id}"]
  # user_data="#!/bin/bash\necho \"wai=dumbServer-${aws_subnet.public_us1a.availability_zone}\">/etc/environment\nsource /etc/environment\nsudo systemctl start docker\ngit clone --recurse-submodules -j8 https://github.com/silui/codedeploy-sample.git\n cd codedeploy-sample/\ngit submodule update --remote --merge\ncd cowork_space\necho $wai\nsudo docker-compose up -d --build"
  user_data="#!/bin/bash\nsudo echo -n \"wai=\" > /etc/environment\nsudo curl http://169.254.169.254/latest/meta-data/instance-id >> /etc/environment\necho $wai\nsudo systemctl start docker\ngit clone --recurse-submodules -j8 https://github.com/silui/codedeploy-sample.git\n cd codedeploy-sample/\ngit submodule update --remote --merge\ncd cowork_space\nsudo docker-compose up -d --build"
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"
  lifecycle              { create_before_destroy = true }
}

resource "aws_autoscaling_group" "example-autoscaling" {
  name                 = "example-autoscaling"
  vpc_zone_identifier  = ["${aws_subnet.public_us1a.id}"]
  launch_configuration = "${aws_launch_configuration.example-launchconfig.name}"
  min_size             = 2
  max_size             = 8
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

# resource "aws_instance" "server-1a" {
#   count = 4
#   ami           = "ami-08c3fac0de21367fc"
#   instance_type = "t2.medium"
#   subnet_id = "${aws_subnet.public_us1a.id}"
#   key_name = "Edward-IAM-keypair"
#   vpc_security_group_ids = ["${aws_security_group.ssh_ping.id}","${aws_security_group.website.id}"]
#   user_data="#!/bin/bash\necho \"wai=dumbServer-${aws_subnet.public_us1a.availability_zone}-${count.index}\">/etc/environment\nsource /etc/environment\nsudo systemctl start docker\ngit clone --recurse-submodules -j8 https://github.com/silui/codedeploy-sample.git\n cd codedeploy-sample/\ngit submodule update --remote --merge\ncd cowork_space\necho $wai\nsudo docker-compose up -d --build"
#   iam_instance_profile = "${aws_iam_instance_profile.main.name}"
# tags{
#     Name = "dumbServer-${aws_subnet.public_us1a.availability_zone}-${count.index}"
#     Production = "true"
#  }
# }

resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  role       = "${aws_iam_role.codedeploy_service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# create a service role for ec2 
resource "aws_iam_role" "instance_profile" {
  name = "codedeploy-instance-profile"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# provide ec2 access to s3 bucket to download revision. This role is needed by the CodeDeploy agent on EC2 instances.
resource "aws_iam_role_policy_attachment" "instance_profile_codedeploy" {
  role       = "${aws_iam_role.instance_profile.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_instance_profile" "main" {
  name = "codedeploy-instance-profile"
  role = "${aws_iam_role.instance_profile.name}"
}

resource "aws_iam_role" "codedeploy_service" {
  name = "codedeploy-service-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_codedeploy_app" "dumb-app" {
  name = "dumb-app"
}

resource "aws_codedeploy_deployment_group" "example" {
  app_name              = "${aws_codedeploy_app.dumb-app.name}"
  deployment_group_name = "dumbserver-group"
  service_role_arn      = "${aws_iam_role.codedeploy_service.arn}"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    elb_info {
      name = "${aws_elb.stupid-elb.name}"
    }
  }
    ec2_tag_set {
    ec2_tag_filter {
      key   = "Production"
      type  = "KEY_AND_VALUE"
      value = "true"
    }
  }


  
}


#---------a bunch of networking nonsence starts here-----0-------
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = "true"
    enable_dns_support = "true"
    tags {
        Name = "vpcpg-vpc"
    }
}

resource "aws_internet_gateway" "main-gw" {
    vpc_id = "${aws_vpc.main.id}"
    tags {
        Name = "main"
    }
}

resource "aws_route_table" "main-public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.main-gw.id}"
    }
    tags {
        Name = "main-public-1"
    }
}
resource "aws_route_table_association" "main-public-1-a" {
    subnet_id = "${aws_subnet.public_us1a.id}"
    route_table_id = "${aws_route_table.main-public.id}"
}


# default subnets
resource "aws_subnet" "public_us1a" {
    cidr_block = "10.0.1.0/24"
  availability_zone = "${var.AWS_REGION}a"
    vpc_id = "${aws_vpc.main.id}"
    map_public_ip_on_launch = "true"
    tags {
        Name = "vpcpg subnet for ${var.AWS_REGION}a"
    }
}


#-------------networking ends here---------------
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
    tags{Name="website"}
}


resource "aws_elb" "stupid-elb" {
    name = "stupid-elb"
    # subnets = ["${aws_subnet.public_us1a.id}","${aws_subnet.public_us1c.id}"]
    subnets = ["${aws_subnet.public_us1a.id}"]
    security_groups = ["${aws_security_group.elb-securitygroup.id}"]
    listener{
        instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol="http"
    }
    health_check {
    healthy_threshold = 2
    unhealthy_threshold = 5
    timeout = 2
    target = "HTTP:80/"
    interval = 5
  }

    # instances = ["${aws_instance.server-1a.*.id}"]

    cross_zone_load_balancing = false
    tags{Name = "dumb-elb"}
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