terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider for terraform
provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_openid_connect_provider" "terraform_oidc" {
  url = "https://app.terraform.io"

  client_id_list = [
    "aws.amazonaws.com",
  ]
  thumbprint_list = ["1dc87b5a0c7f5f82164f1e4baf28d4f5f32c9d44"]
}

resource "aws_iam_role" "terraform_oidc_role" {
  name = "TerraformOIDCAuthRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.terraform_oidc.arn
        }
        Condition = {
          StringLike = {
            "app.terraform.io:sub" = "organization:RaseefAzeez:project:*"
          }
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}


resource "aws_iam_role" "terraform_exec_role" {
  name = "TerraformExecRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowOIDCRoleToAssume"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = aws_iam_role.terraform_oidc_role.arn
        }
        Effect = "Allow"
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_policy" "terraform_exec_policy" {
  name        = "TerrafrormExecPolicy"
  //path        = "/"
  description = "Policy to attach to Execution Role for Terraform"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { 
        Sid      = "AllowS3Access"
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetBucketVersioning"
        ]
        Effect   = "Allow"
        Resource = "*"
      },

      { 
        Sid      = "AllowLambdaAccess"
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:GetFunction",
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      },

      { 
        Sid      = "DynamoDBAccess"
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:UpdateTable",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",

        ]
        Effect   = "Allow"
        Resource = "*"
      },

      { 
        Sid      = "SNSAccess"
        Action = [
          "sns:CreateTopic",
          "sns:Publish",
          "sns:Subscribe",
          
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_exec_policy" {
  role       = aws_iam_role.terraform_exec_role.name
  policy_arn = aws_iam_policy.terraform_exec_policy.arn
}