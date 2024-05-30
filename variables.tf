variable "region" {
  default = "eu-west-2"
}

variable "key_name" {
  default = "ssh_key"
}

variable "public_key_path" {
  default = "/home/devops/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "/home/devops/.ssh/id_rsa"
}

variable "ami" {
  default = "ami-0154dbce80029f1c3"  # Amazon Linux 2 AMI
}

variable "instance_type" {
  default = "t2.micro"
}

variable "s3_bucket" {
  default = "bahramdevopsbucket"
}
