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
    cross_zone_load_balancing = false
    tags{Name = "dumb-elb"}
}