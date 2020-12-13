resource "aws_route53_zone" "r53" {
  name = var.route53_zone_name
  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}

resource "aws_iam_policy" "r53update" {
  name        = "Route53PrivateZoneUpdatePolicy"
  path        = "/"
  description = "Policy to allow updating my priv r53 zone"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/${aws_route53_zone.r53.zone_id}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_route53_record" "test_record" {
  zone_id = aws_route53_zone.r53.zone_id
  name    = "test.${var.route53_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["1.1.1.1"]
}


