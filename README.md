# Terraform Infrastructure Deployment

This repository contains Terraform configuration files to deploy and manage infrastructure on [AWS](https://aws.amazon.com/). Follow the steps below to run the Terraform scripts and provision the infrastructure.

## Prerequisites

1. **Terraform Installation:**
   Ensure that Terraform is installed on your machine. You can download it from the [official Terraform website](https://www.terraform.io/downloads.html).

2. **AWS Credentials:**
   Make sure you have AWS credentials with appropriate permissions. You can set up your credentials using environment variables, AWS CLI, or AWS configuration files.

## Configuration

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/blipppto/blippto-Estate-Infrastructure.git
   ```

## Running Terraform

1. **Export your access keys**

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

2. **Run your terraform file**

```bash
terraform plan
terraform apply -auto-approve
```

Note: If you want to create only one NAT gateway enter modules/vpc_module/variables.tf and set create_one_nat_gateway to true. However if you want ot create one NAT gateway per subnet set the value to false.
