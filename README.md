# Blockchain-client
A simple polygon client written in golang deployed on AWS ECS Fargate

## AWS Architecture
![Alt text](images/architecture.png)

- Multi-zone AWS deployment for resilience, scalability and availability
- Proper security group are in place for block unwanted traffic.
- Controlled outbound and inbound traffic.

## How to run the application

- Step 1: cd in terraform-ecr dir. Terraform code will build an AWS ECR repo and push the application docker image to it.
- Step 2: cd in terraform-ecs dir. Terraform code will create the necessary infrastructure for the docker image to run i.e AWS VPC,AWS ECS cluster, AWS fargate task and service.
- Step 3: Using the dns provided by AWS alb, hit the root endpoint.
- Step 4: You can test the go application manually too via running the command
```
go build -o main
./main
```