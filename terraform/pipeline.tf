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
