resource "aws_security_group" "alb_sg" {
  name = "alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name = "ec2-sg"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
}


resource "aws_lb" "alb" {
  name               = "webserver-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "tg" {
  name        = "webserver-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}


resource "aws_launch_template" "launch_template" {
  name_prefix            = "webserver-lt"
  image_id               = "ami-0bc49f9283d686bab" # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = <<EOF
#!/bin/bash
sudo wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
cd /etc/apt
echo "deb http://nginx.org/packages/ubuntu xenial nginx\ndeb-src http://nginx.org/packages/ubuntu xenial nginx" >> sources.list
sudo apt-get update
sudo apt-get install nginx
sudo service nginx start
EOF
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = var.private_subnets
  target_group_arns   = [aws_lb_target_group.tg.arn]

  desired_capacity = 1
  min_size         = 1
  max_size         = 2
  default_cooldown  = 300

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "asg_policy" {
  name = "asg-tracking-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60.0
  }
}