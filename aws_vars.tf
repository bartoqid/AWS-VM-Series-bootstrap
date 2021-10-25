provider "aws" {
  access_key = ""
  secret_key = ""
  token      = var.aws_session_token
  region     = var.aws_region
}

variable "aws_session_token" {
  description = "Temporary session token used to create instances"
}

variable "aws_region" {
  default = "ap-southeast-2"
}

variable "AZ" {
  default = "ap-southeast-2a"
}

variable "VPCName" {
  default = "student-name-vpc"
}

variable "VPCCIDR" {
  default = "10.x.0.0/16"
}

variable "MGTCIDR_Block" {
  default = "10.x.0.0/24"
}

variable "PublicCIDR_Block" {
  type = list
  default = [
    {
      ip = "10.x.1.0/24"
      name = "untrust-1"
    },
    {
      ip = "10.x.2.0/24"
      name = "untrust-2"
    }
  ]
}

variable "PrivateCIDR_Block" {
  default = "10.x.3.0/24"
}

variable "fw_instance_size" {
  default = "m5.xlarge"
}

variable "MasterS3Bucket" {
  default = ""
}

variable "instance_profile" {
  default = ""
}
  
variable "PANFWRegionAMIID" {
  type = map(string)
  default = {
    "us-west-2"      = "ami-019b369b2201d17e1"
    "ap-northeast-1" = "ami-0ca2e94970201db8d"
    "us-west-1"      = "ami-08e82ba0784b4e5ac"
    "ap-northeast-2" = "ami-0a72f886dd8026c05"
    "ap-southeast-1" = "ami-046798cef2cb2209e"
    "ap-southeast-2" = "ami-02aed591c524aed18"
    "eu-central-1"   = "ami-087597cf0637e3b39"
    "eu-west-1"      = "ami-08e82ba0784b4e5ac"
    "eu-west-2"      = "ami-0cea9a41443754f56"
    "sa-east-1"      = "ami-05a40658314a5dc0f"
    "us-east-1"      = "ami-050725600cf371a1c"
    "us-east-2"      = "ami-0340ae9cf0a892bb9"
    "ca-central-1"   = "ami-0d179c6cdc2589b25"
    "ap-south-1"     = "ami-001923acdc459e458"
  }
}

variable "UbuntuRegionMap" {
  type = map(string)
  default = {
    "us-west-2"      = "ami-efd0428f"
    "ap-northeast-1" = "ami-afb09dc8"
    "us-west-1"      = "ami-2afbde4a"
    "ap-northeast-2" = "ami-66e33108"
    "ap-southeast-1" = "ami-8fcc75ec"
    "ap-southeast-2" = "ami-96666ff5"
    "eu-central-1"   = "ami-060cde69"
    "eu-west-1"      = "ami-a8d2d7ce"
    "eu-west-2"      = "ami-f1d7c395"
    "sa-east-1"      = "ami-4090f22c"
    "us-east-1"      = "ami-80861296"
    "us-east-2"      = "ami-618fab04"
    "ca-central-1"   = "ami-b3d965d7"
    "ap-south-1"     = "ami-c2ee9dad"
  }
}

