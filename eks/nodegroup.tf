resource "aws_iam_role" "node" {
  name = "node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

#resource "aws_security_group" "node" {
#  name        = "cluster-node"
#  description = "Security group for all nodes in the cluster"
#  vpc_id      = aws_vpc.vpc.id

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

#  tags = map(
#     "Name", "cluster-node",
#     "kubernetes.io/cluster/${var.cluster_name}", "shared",
#    )
#}

#resource "aws_security_group_rule" "node-ingress-self" {
#  description              = "Allow node to communicate with each other"
#  from_port                = 0
#  protocol                 = "-1"
#  security_group_id        = aws_security_group.node.id
#  source_security_group_id = aws_security_group.node.id
#  to_port                  = 65535
#  type                     = "ingress"
#}

#resource "aws_security_group_rule" "node-ingress-cluster-https" {
#  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
#  from_port                = 443
#  protocol                 = "tcp"
#  security_group_id        = aws_security_group.node.id
#  source_security_group_id = aws_security_group.cluster.id
#  to_port                  = 443
#  type                     = "ingress"
#}

#resource "aws_security_group_rule" "node-ingress-cluster-others" {
#  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
#  from_port                = 1025
#  protocol                 = "tcp"
#  security_group_id        = aws_security_group.node.id
#  source_security_group_id = aws_security_group.cluster.id
#  to_port                  = 65535
#  type                     = "ingress"
#}

#resource "aws_security_group_rule" "cluster-ingress-node-https" {
#  description              = "Allow pods to communicate with the cluster API Server"
#  from_port                = 443
#  protocol                 = "tcp"
#  security_group_id        = aws_security_group.cluster.id
#  source_security_group_id = aws_security_group.node.id
#  to_port                  = 443
#  type                     = "ingress"
#}

resource "aws_eks_node_group" "nodegroup" {
  cluster_name = aws_eks_cluster.cluster.name
  node_group_name = "nodegroup"
  node_role_arn = aws_iam_role.node.arn
  subnet_ids = data.aws_subnet_ids.sb.ids

  scaling_config {
    desired_size = 1
    max_size = 1
    min_size = 1
  }

  instance_types= [ "t3.small" ]
  disk_size = "50"
  version = "1.18"
  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.cluster-AmazonEC2ContainerRegistryReadOnly,
#    aws_security_group.cluster
  ]
}
