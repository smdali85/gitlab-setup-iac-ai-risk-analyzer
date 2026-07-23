resource "aws_iam_policy" "eks_cluster_access" {
  name        = "${var.app_name}-${var.env}-eks-cluster-access-main"
  path        = "/"
  description = "${var.app_name}-${var.env}-eks-cluster-access-main"
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "eks:ListFargateProfiles",
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:ListUpdates",
                "eks:AccessKubernetesApi",
                "eks:DescribeCluster"
            ],
            "Resource": "arn:aws:eks:ap-south-1:${local.account_id}:cluster/${var.app_name}-${var.env}-main"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "eks:UpdateNodegroupVersion",
                "eks:UpdateClusterVersion",
                "eks:UpdateNodegroupConfig",
                "eks:UpdateClusterConfig"
            ],
            "Resource": "arn:aws:eks:ap-south-1:${local.account_id}:cluster/${var.app_name}-${var.env}-main"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "arn:aws:eks:ap-south-1:${local.account_id}:cluster/${var.app_name}-${var.env}-main"
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "eks:Create*",
                "eks:ListClusters"
            ],
            "Resource": "arn:aws:eks:ap-south-1:${local.account_id}:cluster/${var.app_name}-${var.env}-main"
        }
    ]
}
EOF
}

