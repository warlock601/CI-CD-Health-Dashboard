output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "security_group_id" {
  description = "Security group ID for EC2"
  value       = aws_security_group.ec2.id
}

output "iam_role_arn" {
  description = "IAM role ARN for EC2"
  value       = aws_iam_role.ec2_role.arn
}
