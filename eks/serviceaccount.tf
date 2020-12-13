data "tls_certificate" "cluster" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:external-dns"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "kubesystem" {
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role_policy.json
  name               = "cluster-kubesystem"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy" "r53_update" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Route53PrivateZoneUpdatePolicy"
}

resource "aws_iam_role_policy_attachment" "kubesystem-Route53Update" {
  role       = aws_iam_role.kubesystem.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Route53PrivateZoneUpdatePolicy"
}

resource "aws_iam_role_policy_attachment" "kubesystem-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.kubesystem.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

