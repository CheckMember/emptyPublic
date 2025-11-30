# security groups main.tf

#-----------------------------------------------------------------
# Create Private Load Balancer Security Group
#-----------------------------------------------------------------

resource "aws_security_group" "private-lb" {
  description = "allows HTTP and HTTPS from vpc"
  name        = "private-lb-${var.region}-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "private-lb-${var.region}-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "http_vpc" {
  security_group_id = aws_security_group.private-lb.id

  cidr_ipv4   = var.vpc_cidr
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "https_vpc" {
  security_group_id = aws_security_group.private-lb.id

  cidr_ipv4   = var.vpc_cidr
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "nlb" {
  security_group_id = aws_security_group.private-lb.id

  referenced_security_group_id = aws_security_group.public-lb.id
  #from_port                    = 443
  ip_protocol = "-1"
  #to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "alb-any" {
  security_group_id = aws_security_group.private-lb.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
  #from_port = 443
  #to_port = 443
}

#-----------------------------------------------------------------
# Create Public Load Balancer Security Group
#-----------------------------------------------------------------

resource "aws_security_group" "public-lb" {
  description = "allows HTTP and HTTPS from public addresses"
  name        = "public-lb-${var.region}-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "public-lb-${var.region}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http_local" {
  security_group_id = aws_security_group.public-lb.id

  cidr_ipv4   = var.local_cidr
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "https_local" {
  security_group_id = aws_security_group.public-lb.id

  cidr_ipv4   = var.local_cidr
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  security_group_id = aws_security_group.public-lb.id

  referenced_security_group_id = aws_security_group.private-lb.id
  #from_port                    = 443
  ip_protocol = "-1"
  #to_port                      = 443
}

# Common Security Group Rules

resource "aws_vpc_security_group_egress_rule" "nlb-any" {
  security_group_id = aws_security_group.public-lb.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
  #from_port = 443
  #to_port = 443
}

#-----------------------------------------------------------------
# Create EC2 Security Group
#-----------------------------------------------------------------

resource "aws_security_group" "ec2" {
  description = "ec2 sg"
  name        = "secgroup-ec2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-${var.region}-ec2"
  }
}

# Create EC2 security group rules. Configure EC2 Security Groups for least privilege network access

# Allows ingress traffic only from ALB security group:

resource "aws_vpc_security_group_ingress_rule" "alb-sg" {
  security_group_id = aws_security_group.ec2.id

  referenced_security_group_id = aws_security_group.private-lb.id
  ip_protocol                  = "-1"

  tags = {
    Name = "sg-rule-${var.region}-alb-sg"
  }
}

#-----------------------------------------------------------------
# Allows ingress traffic from Internet to risky ports:
# Wiz Config Rules: 
#   VPC-014	EC2 Security Group should restrict RDP access (TCP:3389)
#   VPC-015	EC2 Security Group should restrict SSH access (TCP:22)
#   VPC-034	EC2 Security Group should restrict access to remote administration ports
#   VPC-029	EC2 Security Group should restrict PostgreSQL access (TCP:5432)
#-----------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "positive1-rdp" {
  security_group_id = aws_security_group.ec2.id
  description = "allows RDP from Internet"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 3389 # this should be detected if from_port is 3389 and cidr_ipv4 is "0.0.0.0/0"
  ip_protocol = "tcp"
  to_port     = 3389

  tags = {
    Name = "sg-rule-${var.region}-positive1-rdp"
  }
}

resource "aws_vpc_security_group_ingress_rule" "positive1-ssh" {
  security_group_id = aws_security_group.ec2.id
  description = "allows SSH from Internet"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22 # this should be detected if from_port is 22 and cidr_ipv4 is "0.0.0.0/0"
  ip_protocol = "tcp"
  to_port     = 22

  tags = {
    Name = "sg-rule-${var.region}-positive1-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "positive1-postgreSQL" {
  security_group_id = aws_security_group.ec2.id
  description = "allows PostgreSQL from Internet"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 5432 # this should be detected if from_port is 5432 and cidr_ipv4 is "0.0.0.0/0"
  ip_protocol = "tcp"
  to_port     = 5432

  tags = {
    Name = "sg-rule-${var.region}-positive1-postgreSQL"
  }
}

resource "aws_vpc_security_group_ingress_rule" "positive1-any" {
  security_group_id = aws_security_group.ec2.id
  description = "allows any from any"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1" # this should be detected if from_port is "-1" (any) and cidr_ipv4 is "0.0.0.0/0"

  tags = {
    Name = "sg-rule-${var.region}-positive1-any"
  }
}


# Allows only https egress traffic to any:

resource "aws_vpc_security_group_egress_rule" "ec2-https-any" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443

  tags = {
    Name = "sg-rule-${var.region}-ec2-https-any"
  }
}

#-----------------------------------------------------------------
# Create VPC Endpoint Security Group
#-----------------------------------------------------------------

resource "aws_security_group" "vpc-endpoint" {
  description = "vpc endpoint sg"
  name        = "secgroup-vpc-endpoint"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-${var.region}-vpc-endpoint"
  }
}

# Create VPC Endpoint security group rules

# Allows HTTPS ingress traffic only from managed instances Private Subnet CIDR(s):
resource "aws_vpc_security_group_ingress_rule" "vpc-https" {
  count             = length(var.private-subnets-cidr)
  security_group_id = aws_security_group.vpc-endpoint.id

  cidr_ipv4   = element(var.private-subnets-cidr, count.index)
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443

  tags = {
    Name = "sg-rule-${var.region}-vpc-https-${count.index}"
  }
}

#-----------------------------------------------------------------
# Create EC2 Security Group using ingress and egress arguments within SG resource (legacy, not recommended approach)
# Allows ingress traffic from Internet to risky ports:
# Wiz Config Rules: 
#   VPC-014	EC2 Security Group should restrict RDP access (TCP:3389)
#   VPC-015	EC2 Security Group should restrict SSH access (TCP:22)
#   VPC-034	EC2 Security Group should restrict access to remote administration ports
#   VPC-029	EC2 Security Group should restrict PostgreSQL access (TCP:5432)
#-----------------------------------------------------------------

# SG allows RDP from Internet"

resource "aws_security_group" "positive2-rdp" {
  description = "allows RDP from Internet"
  name        = "secgroup-positive2-rdp"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 3389
    to_port     = 3389
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-${var.region}-positive2-rdp"
  }
}

# SG allows SSH from Internet"

resource "aws_security_group" "positive2-ssh" {
  description = "allows SSH from Internet"
  name        = "secgroup-positive2-ssh"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-${var.region}-positive2-ssh"
  }
}

# SG allows PostgreSQL from Internet"

resource "aws_security_group" "positive2-postgreSQL" {
  description = "allows PostgreSQL from Internet"
  name        = "secgroup-positive2-postgresql"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-${var.region}-positive2-postgresql"
  }
}

resource "aws_security_group" "positive2-any" {
  description = "allows any from Internet"
  name        = "secgroup-positive2-any"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-${var.region}-positive2-postgresql"
  }
}