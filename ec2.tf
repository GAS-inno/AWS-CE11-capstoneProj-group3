resource "aws_instance" "web" {
  ami                         = var.ec2_ami  # dynamic AMI
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public_1.id  # Updated to use the first public subnet
  vpc_security_group_ids      = [aws_security_group.web_sg.id]  # 👈 use ID, not name
  key_name                    = var.key_name
  associate_public_ip_address = true

  count = 2
  tags = {
    Name = "${var.name_prefix}-ec2-${count.index + 1}" 
  }
}