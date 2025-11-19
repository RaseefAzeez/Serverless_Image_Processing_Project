terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  cloud {
    organization = "Raseefz"

    workspaces {
      name = "Serverless_Image_Processing_Project"
    }
  }
}

# Configure the AWS Provider for terraform

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "terraform_oidc_role" {
  name = "GithubOIDCAuthRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity",
        Effect = "Allow",
        Sid    = "",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:RaseefAzeez/Serverless_Image_Processing_Project:*"
          }
        }
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
  description = "Policy to attach to OIDC role to attach to get access to AWS resources"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { 
        Sid      = "AllowS3Access",
        Effect   = "Allow",
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetBucketVersioning"
        ],
        Resource = "*"
      },

      { 
        Sid      = "AllowLambdaAccess",
        Effect   = "Allow",
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:GetFunction",
          "iam:PassRole"
        ],
        Resource = "*"
      },

      { 
        Sid      = "DynamoDBAccess",
        Effect   = "Allow",
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:UpdateTable",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem"
        ],
        Resource = "*"
      },

      { 
        Sid      = "SNSAccess",
        Effect   = "Allow",
        Action = [
          "sns:CreateTopic",
          "sns:Publish",
          "sns:Subscribe"  
        ],
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_exec_policy" {
  role       = aws_iam_role.terraform_oidc_role.name
  policy_arn = aws_iam_policy.terraform_exec_policy.arn
}