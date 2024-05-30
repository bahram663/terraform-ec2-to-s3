provider "aws" {
  region = var.region
}

resource "aws_security_group" "ssh_access" {
  name        = "ssh-access"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "ec2_instance" {
  ami             = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.ssh_access.name]
  key_name        = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_access_profile.id
  tags = {
    Name = "EC2Instance"
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "ec2_s3_access_policy"
  description = "Policy for accessing S3 bucket"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : "arn:aws:s3:::bahramdevopsbucket/*"   # Adjust bucket ARN
      }
    ]
  })
}

# Attachment of IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# IAM Instance Profile for EC2 instance
resource "aws_iam_instance_profile" "ec2_s3_access_profile" {
  name = "ec2_s3_access_profile"

  role = aws_iam_role.ec2_s3_access_role.name
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = var.s3_bucket
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "BackupBucket"
    Environment = "DevOpsTask"
  }
}

resource "null_resource" "transfer_script" {
  provisioner "file" {
    source      = "backup_script.sh"   # Path to the local backup script
    destination = "/home/ec2-user/backup_script.sh"  # Destination path on the EC2 instance

    connection {
      type        = "ssh"
      host        = aws_instance.ec2_instance.public_ip  # Public IP of the EC2 instance
      user        = "ec2-user"   # User to connect to the EC2 instance
      private_key = file(var.private_key_path)   # Path to the private key for SSH authentication
      port        = 22
    }
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir backup",
      "chmod +x /home/ec2-user/backup_script.sh",
      "echo '0 2 * * * /home/ec2-user/backup_script.sh' | crontab -"  # Add cron job to run script every 5 minutes
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.ec2_instance.public_ip  # Public IP of the EC2 instance
      user        = "ec2-user"   # User to connect to the EC2 instance
      private_key = file(var.private_key_path)   # Path to the private key for SSH authentication
      port        = 22
    }
  }

  depends_on = [aws_instance.ec2_instance]
}

output "public_ip" {
  value = aws_instance.ec2_instance.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.backup_bucket.bucket
}
output "s3_backup_file_url" {
  value = "https://s3.amazonaws.com/${aws_s3_bucket.backup_bucket.bucket}/backup-${formatdate("YYYYMMDDHHmmss", timestamp())}.tar.gz"
}

