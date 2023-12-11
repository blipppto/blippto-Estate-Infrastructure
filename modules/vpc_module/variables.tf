# Environment
variable "environment" {
  type    = string
  default = "Dev" # You can change this to whatever value you want
}

variable "vpc_config" {
  type = object({
    vpc_cidr_block = string
    private_subnet_cidr_blocks = list(string)
    public_subnet_cidr_blocks  = list(string)
    subnet_availability_zones  = list(string)
    create_one_nat_gateway    = bool
  })
  default = {
    vpc_cidr_block = "10.0.0.0/16"
    private_subnet_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnet_cidr_blocks  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    subnet_availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
    create_one_nat_gateway     = true
  }
}

variable "security_groups" {
  type = list(object({
    name          = string
    description   = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
    egress_rules  = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
  }))
  default = [
    {
      name        = "web"
      description = "Web Security Group"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP traffic"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS traffic"
        },
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "SSH traffic"
        },
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        },
      ]
    },
    # Add more security groups as needed
  ]
}


