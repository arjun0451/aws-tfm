variable "region" {
  description = "The AWS region in which resources will be created."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix used for resource naming."
  type        = string
  default     = "tfm-aws"
}

variable "resource_group_name" {
  description = "Placeholder for parity with other clouds; unused by the AWS provider."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Existing VPC ID to use. Empty string creates a new VPC."
  type        = string
  default     = ""
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_id" {
  description = "Existing subnet ID to use for the instance. Empty string creates a new subnet."
  type        = string
  default     = ""
}

variable "subnet_cidr_block" {
  description = "CIDR block of the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance."
  type        = string
  default     = "tfm-aws-web"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access."
  type        = string
  default     = ""
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance."
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GiB."
  type        = number
  default     = 20
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}
