output "vpc_id" {
  value = aws_vpc.main.id

  # this otherwsie the ALB will always be "provisioning"
  depends_on = [aws_route_table_association.ngw_assoc]
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}