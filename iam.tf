# ECS

resource "aws_iam_role" "task_execution_role" {
  name = "${var.env_prefix}-task-execution-role-${var.environment}"
  tags = var.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "task_execution_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ssm:GetParameters",
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_execution_policy_attach" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_policy.arn
}

resource "aws_iam_role" "task_role" {
  name = "${var.env_prefix}-task-role-${var.environment}"
  tags = var.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "task_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_policy_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}

# CODEBUILD

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "${var.env_prefix}-${var.environment}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:*", "codebuild:*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:BatchCheckLayerAvailability", "ecr:PutImage"]
        Resource = aws_ecr_repository.app_repository.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"]
        Resource = aws_ecr_repository.app_repository.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      }
    ]
  })
}

# CODEPIPELINE

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.env_prefix}-${var.environment}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.env_prefix}-task-execution-role-${var.environment}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.env_prefix}-task-role-${var.environment}"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github_connection.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
    resources = [aws_codebuild_project.codebuild.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecs:RegisterTaskDefinition"]
    resources = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = [
      aws_codedeploy_app.ecs_app.arn,
      aws_codedeploy_deployment_group.ecs_deployment_group.arn,
      "arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:CodeDeployDefault.ECSAllAtOnce"
    ]
  }
}


resource "aws_iam_role_policy" "codepipeline_policy" {
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

# CODEDEPLOY

data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name               = "${var.env_prefix}-${var.environment}-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json
}

resource "aws_iam_role_policy" "codedeploy_policy" {
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:CreateTaskSet",
          "ecs:DeleteTaskSet",
          "ecs:UpdateServicePrimaryTaskSet"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DeleteLifecycleHook",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:PutLifecycleHook",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:EnableMetricsCollection",
          "autoscaling:DescribePolicies",
          "autoscaling:DescribeScheduledActions",
          "autoscaling:DescribeNotificationConfigurations",
          "autoscaling:SuspendProcesses",
          "autoscaling:ResumeProcesses",
          "autoscaling:AttachLoadBalancers",
          "autoscaling:AttachLoadBalancerTargetGroups",
          "autoscaling:PutScalingPolicy",
          "autoscaling:PutScheduledUpdateGroupAction",
          "autoscaling:PutNotificationConfiguration",
          "autoscaling:PutWarmPool",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DeleteAutoScalingGroup",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:*",
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:PutObjectAcl"
        ]
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          "*"
        ]
        Condition = {
          StringLike = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}
