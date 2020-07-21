resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = var.vpc_id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name   = "ec2-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "alb" {
  name               = "webserver-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  timeouts {
    create = "20m"
    delete = "20m"
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "webserver-tg"
  port        = 3000
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


resource "aws_iam_role" "ec2forssm" {
  name = "RoleforEC2forSSM"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2forssm" {
  name = "InstanceProfileEC2forSSM"
  role = aws_iam_role.ec2forssm.name
}

resource "aws_iam_role_policy_attachment" "ec2forssm" {
  role       = aws_iam_role.ec2forssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_launch_template" "launch_template" {
  name                   = "webserver-lt"
  image_id               = "ami-0a58e22c727337c51" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2forssm.arn
  }

  user_data = base64encode(<<EOF
#!/bin/bash
sudo yum install -y git
sudo git clone https://github.com/Noatz/todo.git
cd todo
curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo yum install -y nodejs
sudo npm i
sudo npm start
EOF
  )
}

resource "aws_autoscaling_group" "asg" {
  name                    = "asg-webserver"
  service_linked_role_arn = "arn:aws:iam::685853460131:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  vpc_zone_identifier     = var.private_subnets
  target_group_arns       = [aws_lb_target_group.tg.arn]

  desired_capacity = 1
  min_size         = 1
  max_size         = 2
  default_cooldown = 150

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "asg_policy" {
  name                   = "asg-tracking-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60.0
  }
}