output "master_worker_ip_address" {
  value       = aws_instance.master_worker.public_ip
  description = "The public IP address of the master worker"
}

output "master_worker_id" {
  value       = aws_instance.master_worker.id
  description = "The ID of the master worker"
}

output "master_worker_arn" {
  value       = aws_instance.master_worker.arn
  description = "The ARN of the master worker"
}
