data "aws_region" "current" {
  current = true
}
data "aws_caller_identity" "current" {}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "encrypted_password" {
  value = "${aws_iam_user_login_profile.user.encrypted_password}"
}

locals {
  region_account = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
}

data "aws_iam_role" "EC2_AssumedRole" {
  name = "EC2_AssumedRole"
}

data "aws_iam_instance_profile" "EC2_AssumedRole" {
  name = "EC2_AssumedRole"
}

resource "aws_iam_group" "generated" {
  name = "generated"
  path = "/generated/"
}

resource "aws_iam_user" "user" {
  name = "hi"
  path = "/generated/"
  force_destroy = true
}

resource "aws_iam_user_login_profile" "user" {
  user    = "${aws_iam_user.user.name}"
  pgp_key = "${file("~/.ssh/stevejackson.asc")}"
}

# generate keys for service account user
resource "aws_iam_access_key" "user_keys" {
  user = "${aws_iam_user.user.name}"
}

resource "aws_iam_group_membership" "generated" {
  name = "generated"

  users = [
    "${aws_iam_user.user.name}",
  ]

  group = "${aws_iam_group.generated.name}"
}

resource "aws_iam_group_policy" "group_policy" {
  name  = "group_policy"
  group = "${aws_iam_group.generated.id}"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Sid": "SeeChangePassword",
         "Effect": "Allow",
         "Action": "iam:GetAccountPasswordPolicy",
         "Resource": "*"
      },
      {
         "Sid": "ChangePassword",
         "Effect": "Allow",
         "Action": "iam:ChangePassword",
         "Resource": "${aws_iam_user.user.arn}"
      },
      {
         "Sid": "NonResourceBasedReadOnlyPermissions",
         "Action": [
            "ec2:Describe*",
            "ec2:CreateKeyPair",
            "ec2:CreateSecurityGroup",
            "iam:GetInstanceProfile",
            "iam:ListInstanceProfiles"
         ],
         "Effect": "Allow",
         "Resource": "*"
      },
      {
         "Sid": "IAMPassRoleToInstance",
         "Action": [
            "iam:PassRole"
         ],
         "Effect": "Allow",
         "Resource": "${data.aws_iam_role.EC2_AssumedRole.arn}"
      },
      {
         "Sid": "AllowInstanceActions",
         "Effect": "Allow",
         "Action": [
            "ec2:RebootInstances",
            "ec2:StopInstances",
            "ec2:TerminateInstances",
            "ec2:StartInstances",
            "ec2:AttachVolume",
            "ec2:DetachVolume"
         ],
         "Resource": "arn:aws:ec2:${local.region_account}:instance/*",
         "Condition": {
            "StringEquals": {
               "ec2:InstanceProfile": "${data.aws_iam_instance_profile.EC2_AssumedRole.arn}"

            }
         }
      },
      {
         "Sid": "EC2RunInstances",
         "Effect": "Allow",
         "Action": "ec2:RunInstances",
         "Resource": "arn:aws:ec2:${local.region_account}:instance/*",
         "Condition": {
            "StringEquals": {
               "ec2:InstanceProfile": "${data.aws_iam_instance_profile.EC2_AssumedRole.arn}"
            }
         }
      }
   ]
}
EOF
}

resource "aws_iam_user_policy" "policy" {
  name = "${aws_iam_user.user.name}"
  user = "${aws_iam_user.user.name}"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Sid": "EC2RunInstancesSubnet",
         "Effect": "Allow",
         "Action": "ec2:RunInstances",
         "Resource": "arn:aws:ec2:${local.region_account}:subnet/*",
         "Condition": {
            "StringEquals": {
               "ec2:vpc": "${aws_vpc.main.id}"
            }
         }
      },
      {
         "Sid": "RemainingRunInstancePermissions",
         "Effect": "Allow",
         "Action": "ec2:RunInstances",
         "Resource": [
            "arn:aws:ec2:${local.region_account}:volume/*",
            "arn:aws:ec2:${data.aws_region.current.name}::image/*",
            "arn:aws:ec2:${data.aws_region.current.name}::snapshot/*",
            "arn:aws:ec2:${local.region_account}:network-interface/*",
            "arn:aws:ec2:${local.region_account}:key-pair/*",
            "arn:aws:ec2:${local.region_account}:security-group/*"
         ]
      },
      {
         "Sid": "EC2VpcNonresourceSpecificActions",
         "Effect": "Allow",
         "Action": [
            "ec2:DeleteNetworkAcl",
            "ec2:DeleteNetworkAclEntry",
            "ec2:DeleteRoute",
            "ec2:DeleteRouteTable",
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupEgress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:DeleteSecurityGroup"
         ],
         "Resource": "*",
         "Condition": {
            "StringEquals": {
               "ec2:vpc": "${aws_vpc.main.id}"
            }
         }
      }
   ]
}
EOF
}
