provider "aws" {
  region  = "ap-south-1"
  profile = "mrtiwari"
}


resource "tls_private_key" "tls_key" {
  algorithm = "RSA"
}


resource "aws_key_pair" "generated_key" {
  key_name   = "my-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"

    depends_on = [
    tls_private_key.tls_key
  ]
}


resource "local_file" "key-file" {
  content  = "tls_private_key.tls_key.private_key_pem"
  filename = "my-key.pem"


  depends_on = [
    tls_private_key.tls_key
  ]
}


resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-a7c3decf"

 ingress {
    description = "SSH Rule"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "HTTP Rule"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


resource "aws_instance" "web" {
  ami             = "ami-005956c5f0f757d37"
  instance_type   = "t2.micro"
  key_name        = "my-key"
  security_groups = ["allow_tls"]


  
  tags = {
    Name = "Infraos"
   
  }

 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key   =   file("C:/users/Aki/Desktop/terra/task1/my-key.pem")
    host     = aws_instance.web.public_ip
  }


provisioner "remote-exec" {
    inline = [
       "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo rm -rf /var/www/html/*",
      "sudo systemctl enable httpd",
      "git clone https://github.com/akashtiwari370/fbPage"
    ]
  }
}


resource "aws_s3_bucket" "terra-bucket" {
  bucket = "git-code-for-terra"
  acl    = "public-read"
}


resource "aws_s3_bucket_object" "bucket-push" {
  bucket = "aws_s3_bucket.terra-bucket.bucket"
  key   =   "fbbg.png"
  source = "https://github.com/akashtiwari370/fbbg.png"
  acl    = "public-read"
}



resource "aws_cloudfront_distribution" "s3-web-distribution" {
  origin {
    domain_name = "git-code-for-terra.s3.amazonaws.com"
    origin_id   = aws_s3_bucket.terra-bucket.id
  }


  enabled             = true
  is_ipv6_enabled     = true
 


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.terra-bucket.id


    forwarded_values {
      query_string = false


      cookies {
        forward = "none"
      }
    }


    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN"]
    }
  }


  tags = {
    Name        = "Terra-CF-Distribution"
    Environment = "Production"
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }


  depends_on = [
    aws_s3_bucket.terra-bucket
  ]
}








resource "aws_ebs_volume" "terra-vol" {
  availability_zone = aws_instance.web.availability_zone
  size              = 8
  
  tags = {
    Name = "ebs-vol"
  }
}







resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.terra-vol.id
  instance_id  = aws_instance.web.id
  force_detach = true


  provisioner "remote-exec" {
    connection {
      agent       = "false"
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.tls_key.private_key_pem
      host        = aws_instance.web.public_ip
    }
    
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html/",
      "sudo cp /home/ec2-user/webapp.html /var/www/html/"
    ]
  }


  depends_on = [
    aws_instance.web,
    aws_ebs_volume.terra-vol
  ]
}
  

  