provider "aws" { 
    region = "${var.AWS_REGION}"
}

resource "aws_instance" "server-1a" {
  count = 2
  ami           = "ami-693d4009"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_us1a.id}"
  key_name = "Edward-IAM-keypair"
  vpc_security_group_ids = ["${aws_security_group.ssh_ping.id}","${aws_security_group.website.id}"]
  user_data= "#!/bin/bash\nsudo -s\napt-get update\napt-get -y install nginx\nMYIP=`ifconfig | grep 'addr:10' | awk '{ print $2 }' | cut -d ':' -f2`\necho 'this is: '$MYIP > /var/www/html/index.html\necho chicken\nnginx"
#   associate_public_ip_address = "false"
}



# resource "aws_instance" "server-1c" {
#   ami           = "ami-693d4009"
#   instance_type = "t2.micro"
#   subnet_id = "${aws_subnet.public_us1c.id}"
#   key_name = "Edward-IAM-keypair"
#   vpc_security_group_ids = ["${aws_security_group.ssh_ping.id}","${aws_security_group.website.id}"]
#   user_data= "#!/bin/bash\nsudo -s\napt-get update\napt-get -y install nginx\nMYIP=`ifconfig | grep 'addr:10' | awk '{ print $2 }' | cut -d ':' -f2`\necho 'this is: '$MYIP > /var/www/html/index.html\necho chicken\nnginx"
# }

# resource "aws_instance" "jenkin-server" {
#   ami           = "ami-693d4009"
#   instance_type = "t2.micro"
#   subnet_id = "${aws_subnet.public_us1c.id}"
#   key_name = "Edward-IAM-keypair"
#   vpc_security_group_ids = ["${aws_security_group.ssh_ping.id}","${aws_security_group.website.id}"]
# #   user_data= "#!/bin/bash\nsudo -s\napt-get update\napt-get -y install nginx\nMYIP=`ifconfig | grep 'addr:10' | awk '{ print $2 }' | cut -d ':' -f2`\necho 'this is: '$MYIP > /var/www/html/index.html\necho chicken\nnginx"
# }


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

resource "aws_route_table" "main-private" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat.id}"
    }
    tags {
        Name = "main-private-1"
    }
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.public_us1a.id}"
}

resource "aws_route_table_association" "main-private-1-a" {
    subnet_id = "${aws_subnet.private_us1a.id}"
    route_table_id = "${aws_route_table.main-private.id}"
}



# resource "aws_route_table_association" "main-public-1-c" {
#     subnet_id = "${aws_subnet.public_us1c.id}"
#     route_table_id = "${aws_route_table.main-public.id}"
# }

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

resource "aws_subnet" "private_us1a" {
    cidr_block = "10.0.3.0/24"
  availability_zone = "${var.AWS_REGION}a"
    vpc_id = "${aws_vpc.main.id}"
    map_public_ip_on_launch = "false"
    tags {
        Name = "vpcpg subnet for ${var.AWS_REGION}a"
    }
}

# resource "aws_subnet" "public_us1c" {
#     cidr_block = "10.0.2.0/24"
#   availability_zone = "${var.AWS_REGION}c"
#     vpc_id = "${aws_vpc.main.id}"
#     map_public_ip_on_launch = "true"
#     # map_public_ip_on_launch = "false"
#     tags {
#         Name = "vpcpg subnet for ${var.AWS_REGION}c"
#     }
# }


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
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

    instances = ["${aws_instance.server-1a.*.id}"]

    # cross_zone_load_balancing = true
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