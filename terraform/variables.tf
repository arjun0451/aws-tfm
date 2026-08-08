variable "region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
  default     = "aws-tfm"
}

variable "environment" {
  description = "Deployment environment, e.g. production"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread the infrastructure across"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type for the web servers"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key pair name used for EC2 instance launch (optional; SSH is not required when using SSM Session Manager)"
  type        = string
  default     = ""
}

variable "web_port" {
  description = "Port the web servers listen on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path used by the ALB health check to verify application health"
  type        = string
  default     = "/health.html"
}

variable "enable_ssm_endpoints" {
  description = "Whether to create VPC interface endpoints for SSM to keep private instances fully private"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on the ALB. Set to false before running terraform destroy to avoid blocking teardown."
  type        = bool
  default     = true
}
