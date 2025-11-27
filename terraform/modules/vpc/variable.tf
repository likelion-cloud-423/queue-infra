variable "name_prefix" {
  type    = string
  default = "team3"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.23.0.0/16"
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.23.1.0/24", "10.23.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.23.11.0/24", "10.23.12.0/24"]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
