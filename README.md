# Obelion Infrastructure as Code - Terraform

## Overview
This repository contains complete Infrastructure as Code (IaC) for Obelion's cloud infrastructure using Terraform on AWS.

It provisions:
- **VPC** with public and private subnets
- **2 EC2 instances** (Frontend: Node.js/Uptime Kuma, Backend: Laravel/PHP)
- **RDS MySQL 8** database (private, no public access)
- **Security Groups** for proper network isolation
- **Internet Gateway** and routing configuration

## Architecture
<img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/4966a6bb-5c27-4e5c-a5b8-5b775e2d4712" />

```
Internet
   |
   v
[IGW]
   |
   v
[VPC: 10.0.0.0/16]
   |
   +---> [Public Subnet: 10.0.1.0/24]
   |           |
   |           +---> [Frontend EC2] (Uptime Kuma)
   |           +---> [Backend EC2] (Laravel)
   |
   +---> [Private Subnet: 10.0.2.0/24]
            |
            +---> [RDS MySQL 8] (obeliondb)

            <img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/e6e67c19-02a1-443a-a373-53af96c4333b" />

```

## Prerequisites
- Terraform >= 1.2.0
- AWS CLI configured with valid credentials
- AWS Account with appropriate permissions

## File Structure
```
.
├── provider.tf           # AWS provider configuration
├── variables.tf          # Input variables (region, CIDR, db credentials)
├── main.tf              # Core infrastructure resources (VPC, EC2, RDS)
├── outputs.tf           # Outputs (IPs, endpoints, subnet IDs)
├── modules/
│   └── security_groups/
│       └── main.tf      # Frontend, Backend, RDS security groups
└── README.md            # This file
```

## Quick Start

### 1. Initialize Terraform
```bash
cd obelion-infra-terraform
terraform init
```

### 2. Set Database Password
```bash
# Set password via environment variable (recommended for security)
export TF_VAR_db_password="your-secure-password"

# Or use terraform.tfvars file
echo 'db_password = "your-secure-password"' > terraform.tfvars
```

### 3. Review the Plan
```bash
terraform plan
```

### 4. Apply Configuration
```bash
terraform apply
```

### 5. View Outputs
```bash
terraform output
```

You'll get:
- `frontend_public_ip`: IP of Frontend EC2
- `backend_public_ip`: IP of Backend EC2
- `rds_endpoint`: Database endpoint (internal only)

## Configuration

### Variables (variables.tf)
| Variable | Default | Description |
|----------|---------|-------------|
| aws_region | eu-central-1 | AWS region |
| vpc_cidr | 10.0.0.0/16 | VPC CIDR block |
| public_subnet_cidr | 10.0.1.0/24 | Public subnet |
| private_subnet_cidr | 10.0.2.0/24 | Private subnet (RDS) |
| instance_type | t3.micro | EC2 instance type |
| db_username | admin | RDS master username |
| db_password | REQUIRED | RDS master password |
| environment | production | Environment tag |

## Security Groups

### Frontend SG
- Allow SSH (22), HTTP (80), HTTPS (443) from anywhere (0.0.0.0/0)
- Outbound: Allow all

### Backend SG
- Allow SSH (22), HTTP (80), HTTPS (443) from anywhere (0.0.0.0/0)
- Outbound: Allow all (to reach RDS)

### RDS SG
- Allow MySQL (3306) from Backend SG only
- Outbound: Allow all

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## CI/CD Integration

See related repositories:
- **Frontend CI/CD**: obelion-frontend-cicd (Uptime Kuma + GitHub Actions)
- **Backend CI/CD**: obelion-backend-cicd (Laravel + GitHub Actions)

## CloudWatch Monitoring

Configure CloudWatch alarms for:
- CPU > 50%: Send alert to SNS
- RDS connections
- Memory usage

## Azure Migration

For migration to Azure, see: AZURE_MIGRATION_PLAN.md

## Author
@eslam-devops

## License
MIT
