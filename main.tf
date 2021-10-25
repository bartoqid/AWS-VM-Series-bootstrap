resource "aws_vpc" "main" {
  cidr_block = var.VPCCIDR
  tags = {
    Name = var.VPCName
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "myKey"       # Create "myKey" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./myKey.pem"
  }
}

#Create the 1 management, 2 public and 1 private subnet
resource "aws_subnet" "NewMGTSubnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.MGTCIDR_Block
  availability_zone = var.AZ
  tags = {
    Name = "MGT"
  }
}

resource "aws_subnet" "NewPublicSubnet" {
  count             = "${length(var.PublicCIDR_Block)}"
  vpc_id            = aws_vpc.main.id
  cidr_block        = "${lookup(element(var.PublicCIDR_Block, count.index), "ip")}"
  availability_zone = var.AZ
  tags = {
    Name            = "${lookup(element(var.PublicCIDR_Block, count.index), "name")}"
  }
}

resource "aws_subnet" "NewPrivateSubnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.PrivateCIDR_Block
  availability_zone = var.AZ
  tags = {
    Name = "Private1"
  }
}

#Create management, untrust and trust route 
resource "aws_route_table" "management" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "mgtroute"
  }
}

resource "aws_route_table" "untrust" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Untrustroute1"
  }
}

resource "aws_route_table" "trust" {
  vpc_id = aws_vpc.main.id
  depends_on = [
    aws_vpc.main,
    aws_network_interface.FWPrivate12NetworkInterface,
  ]
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.FWPrivate12NetworkInterface.id
  }
  tags = {
    Name = "Trustroute1"
  }
}

#Route table association
resource "aws_route_table_association" "mgt" {
  subnet_id      = aws_subnet.NewMGTSubnet.id
  route_table_id = aws_route_table.management.id
}

resource "aws_route_table_association" "untrust" {
  for_each = {
    for k, v in aws_subnet.NewPublicSubnet : k => v
  }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.untrust.id
}

resource "aws_route_table_association" "trust" {
  subnet_id      = aws_subnet.NewPrivateSubnet.id
  route_table_id = aws_route_table.trust.id
}

#Create IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW1"
  }
}

#Create Security Group
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Allow-all1"
  }
}

#Create 1 management, 2 untrust and 1 trust firewall Interfaces
resource "aws_network_interface" "FWManagementNetworkInterface" {
  subnet_id         = aws_subnet.NewMGTSubnet.id
  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
  tags = {
    Name = "FWManagementNIC"
  }
}

resource "aws_network_interface" "FWPublic1NetworkInterface" {
  subnet_id         = aws_subnet.NewPublicSubnet[0].id
  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
  tags = {
    Name = "FWExternalNIC1"
  }
}

resource "aws_network_interface" "FWPublic2NetworkInterface" {
  subnet_id         = aws_subnet.NewPublicSubnet[1].id
  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
  tags = {
    Name = "FWExternalNIC2"
  }
}

resource "aws_network_interface" "FWPrivate12NetworkInterface" {
  subnet_id         = aws_subnet.NewPrivateSubnet.id
  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
  private_ips_count = 0
  tags = {
    Name = "FWTrustNIC"
  }
}

#Create 3 FW EIPs (management and 2 public interfaces)
resource "aws_eip" "ManagementElasticIP" {
  vpc = true
  tags = {
    Name = "ManagementEIP"
  }
}

resource "aws_eip" "PublicElasticIP1" {
  vpc = true
  tags = {
    Name = "PublicEIP1"
  }
}

resource "aws_eip" "PublicElasticIP2" {
  vpc = true
  tags = {
    Name = "PublicEIP2"
  }
}

#Create firewall EIP association
resource "aws_eip_association" "FWEIPManagementAssociation" {
  network_interface_id = aws_network_interface.FWManagementNetworkInterface.id
  allocation_id        = aws_eip.ManagementElasticIP.id
}

resource "aws_eip_association" "FWEIPPublicAssociation1" {
  network_interface_id = aws_network_interface.FWPublic1NetworkInterface.id
  allocation_id        = aws_eip.PublicElasticIP1.id
}

resource "aws_eip_association" "FWEIPPublicAssociation2" {
  network_interface_id = aws_network_interface.FWPublic2NetworkInterface.id
  allocation_id        = aws_eip.PublicElasticIP2.id
}

#Create Linux interface
resource "aws_network_interface" "WPNetworkInterface" {
  subnet_id         = aws_subnet.NewPrivateSubnet.id
  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
  tags = {
    Name = "HostNIC"
  }
}

#Create FW instances
resource "aws_instance" "FWInstance" {
  disable_api_termination              = false
  iam_instance_profile                 = var.instance_profile
  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true
  ami                                  = var.PANFWRegionAMIID[var.aws_region]
  instance_type                        = var.fw_instance_size

  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_type           = "gp2"
    delete_on_termination = true
    volume_size           = 60
  }

  monitoring = false

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.FWManagementNetworkInterface.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.FWPublic1NetworkInterface.id
  }

    network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.FWPublic2NetworkInterface.id
  }

  network_interface {
    device_index         = 3
    network_interface_id = aws_network_interface.FWPrivate12NetworkInterface.id
  }

  user_data = base64encode(
    join("", ["vmseries-bootstrap-aws-s3bucket=", var.MasterS3Bucket]),
  )
  tags = {
    Name = "vmseriesFirewall"
  }
}

#Create Linux instance
resource "aws_instance" "WPWebInstance" {
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  ami                                  = var.UbuntuRegionMap[var.aws_region]
  instance_type                        = "t2.micro"

  key_name   = "myKey"
  monitoring = false

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.WPNetworkInterface.id
  }
  tags = {
    Name = "Linuxhost"
    Type = "Dev-servers"
  }
}

