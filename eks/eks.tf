#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "cluster-role" {
  name = "cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster-role.name
}

#resource "aws_security_group" "cluster" {
#  name        = "cluster-sg"
#  description = "Cluster communication with worker nodes"
#  vpc_id      = aws_vpc.vpc.id
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#  ingress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Name = "cluster-sg"
#  }
#}


# Find "our" VPC
data "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

data aws_subnet_ids "sb" {
  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster-role.arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager" ]

  vpc_config {
    # security_group_ids = [aws_security_group.cluster.id]
    subnet_ids         = data.aws_subnet_ids.sb.ids
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
    aws_cloudwatch_log_group.cluster
  ]
}

resource "null_resource" "tag-subnets" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
      aws --profile=${var.aws_profile} ec2 create-tags --resources ${join(" ", data.aws_subnet_ids.sb.ids)} \
        --tags 'Key="kubernetes.io/cluster/${var.cluster_name}",Value=shared'
EOF
  }
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 3
}
