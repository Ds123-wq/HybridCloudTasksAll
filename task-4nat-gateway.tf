provider "aws" {
  region  = "ap-south-1"
  profile = "deepak"
}

# create vpc
resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames=true
  enable_dns_support =true
 tags = {
    Name = "deepak-vpc"
  }
}

#create two subnet :- public and private
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-subnet-1a"
  }
}


resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = false
  availability_zone ="ap-south-1b"
  tags = {
    Name = "private-subnet-1b"
  }
}

#Create Internet gateway and attach to deepak-vpc
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "My-internet-gateway"
  }

}


#Create route table and associate to public subnet and add internet gateway
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-routing-table"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.r.id
}


resource "aws_eip" "nat" {
  vpc=true
  
}
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnet.id
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "NAT-gateway"
  }
}
resource "aws_route_table" "private-sub" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

 

  tags = {
    Name = "Route-DB"
  }
}
resource "aws_route_table_association" "nat" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-sub.id
}



#Create Security group for wordpress
resource "aws_security_group" "web" {
  name        = "wordpress-SG"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-SG"
  }
}



#Create Security group for mysql
resource "aws_security_group" "db" {
  name        = "mysql-SG"
  description = "Allow webserver-SG inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "MYSQL"
    security_groups = [aws_security_group.web.id]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql-SG"
  }
}


# launch wordpress  instances
resource "aws_instance" "wordpress" {
 ami = "ami-000cbce3e1b899ebd"
 instance_type = "t2.micro"
 associate_public_ip_address = true
 subnet_id = aws_subnet.public-subnet.id
 vpc_security_group_ids = [aws_security_group.web.id]
 key_name = "myfirstkey-pair"

 tags ={
   Name = "wordpress"
 }
depends_on = [
    aws_route_table_association.a
  ]

provisioner "local-exec" {
  command = "chrome ${aws_instance.wordpress.public_ip}"

}
}

# launch mysql instance
resource "aws_instance" "mysql" {
 ami = "ami-08706cb5f68222d09"
 instance_type = "t2.micro"
 associate_public_ip_address = false
 subnet_id = aws_subnet.private-subnet.id
 vpc_security_group_ids = [aws_security_group.db.id]
 key_name = "cloudkey"

 tags ={
   Name = "mysql"
 }
}



