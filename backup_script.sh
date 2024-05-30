#!/bin/bash

# Install tar if not already installed
sudo yum install -y tar

# Create a backup directory in the home directory of the EC2 user
mkdir -p /home/ec2-user/backup

# Compress the contents of the specified directory into a single tar.gz file
tar -zcvf /home/ec2-user/backup/backup_$(date +%Y%m%d_%H%M%S).tar.gz /home/ec2-user/backup/*

# Upload the compressed backup file to the S3 bucket with a timestamp in the filename
aws s3 cp /home/ec2-user/backup/backup_$(date +%Y%m%d_%H%M%S).tar.gz s3://bahramdevopsbucket/

