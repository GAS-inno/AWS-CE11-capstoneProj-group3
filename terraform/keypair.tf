resource "null_resource" "generate_keypair" {
  # Create keypair only if missing
  provisioner "local-exec" {
    command = <<EOT
      if [ ! -f "${path.module}/../generated_keys/${var.key_name}" ]; then
        mkdir -p ${path.module}/../generated_keys
        ssh-keygen -t rsa -b 4096 -f ${path.module}/generated_keys/${var.key_name} -N ""
      fi
    EOT
  }
}

# Wait until the file is created, then read it safely
data "local_file" "public_key" {
  depends_on = [null_resource.generate_keypair]
  filename   = "${path.module}/generated_keys/${var.key_name}.pub"
}

# Upload key to AWS
resource "aws_key_pair" "generated" {
  key_name   = "${var.key_name}-${timestamp()}"
  public_key = data.local_file.public_key.content
}
