output "public_ip" {
    value = module.ec2-instance.public_ip
}

output "public_dns" {
    value = module.ec2-instance.public_dns
}