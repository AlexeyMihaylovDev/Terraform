

provider "aws" {
  region = var.region
}


resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Alexey-vpc"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Alexey-gateway"
  }

}

resource "aws_route" "route" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id


}
data "aws_availability_zones" "available" {
}

resource "aws_subnet" "main" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "alexey-subnet-${count.index}"
  }
}

# resource "aws_eip_association" "eip_assoc" {
#   instance_id   = aws_instance.my_Amazon_linux.id
#   allocation_id = "eipalloc-02ea054c8065f1c11"
# }


resource "aws_instance" "my_Amazon_linux" {
  count                  = var.prefix
  ami                    = "ami-0a1ee2fb28fe05df3" #Amazon Linux AMI
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.alexey-secure-group.id]

  user_data = templatefile("user_data.sh.tpl", {
    f_name = "Alexey",
    l_name = "Miha",
    names  = ["Vasya", "kolya", "Deny", "john", "Masha"]
  })
  tags = {
    Name = "Terraform webServer"
  }
  lifecycle {
    # ignore_changes        = ["ami", "user_data"]
    create_before_destroy = true
  }
}

resource "aws_security_group" "alexey-secure-group" {
  name        = "web_server_secure_group"
  description = "Allow TLS inbound traffic"

  dynamic "ingress" {
    for_each = ["80", "443", "8080", "1541", "9092", "9093", "8081"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_servers"
  }
}
