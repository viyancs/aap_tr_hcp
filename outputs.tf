#############################################
# OUTPUTS
#############################################

output "instance_id" {
  value = aws_instance.vm.id
}

output "public_ip" {
  value = aws_instance.vm.public_ip
}

output "ssh_command" {
  value = "ssh -p ${var.ssh_port} ubuntu@${aws_instance.vm.public_ip}"
}