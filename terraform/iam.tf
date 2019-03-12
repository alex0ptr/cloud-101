resource "aws_iam_instance_profile" "app" {
  name_prefix = "app-${local.stack}"
  role        = "${aws_iam_role.app.name}"
}

resource "aws_iam_role" "app" {
  name_prefix = "app-${local.stack}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "access_dynamodb_jokes" {
  name_prefix = "app-may-access-dynamodb-jokes-${local.stack}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamoDb:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.app_jokes.arn}"
    },
    {
      "Action": [
          "dynamoDb:CreateTable",
          "dynamoDb:DeleteTable"
      ],
      "Effect": "Deny",
      "Resource": "${aws_dynamodb_table.app_jokes.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "allow_dynamo_jokes_to_app" {
  role       = "${aws_iam_role.app.name}"
  policy_arn = "${aws_iam_policy.access_dynamodb_jokes.arn}"
}

resource "aws_iam_policy" "access_app_ecr" {
  name_prefix = "app-may-pull-images-${local.stack}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:ListImages",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Effect": "Allow",
      "Resource": "${data.aws_ecr_repository.app.arn}"
    },
    {
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "allow_ecr_to_app" {
  role       = "${aws_iam_role.app.name}"
  policy_arn = "${aws_iam_policy.access_app_ecr.arn}"
}
