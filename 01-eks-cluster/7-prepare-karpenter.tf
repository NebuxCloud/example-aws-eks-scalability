data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  name               = format("%s-karpenter-controller", var.eks_cluster_name)
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json
}

resource "aws_iam_policy" "karpenter_controller" {
  name   = format("%s-karpenter-controller-policy", var.eks_cluster_name)
  policy = file("./policies/controller-trust-policy.json")
}

resource "aws_iam_instance_profile" "karpenter" {
  name = format("%s-karpenter-instance-profile", var.eks_cluster_name)
  role = aws_iam_role.karpenter_controller.name
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "karpenter_controller_policy" {
  policy_arn = aws_iam_policy.karpenter_controller.arn
  role       = aws_iam_role.karpenter_controller.name
}

# Create SQS queue for interruption events
resource "aws_sqs_queue" "interruption_queue" {
  name = var.eks_cluster_name
}

# Install Karpenter
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "karpenter" {
  namespace = "kube-system"

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"

  version = "1.0.1"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.cluster.id
  }


  set {
    name  = "settings.interruptionQueue"
    value = aws_eks_cluster.cluster.id
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  depends_on = [aws_eks_cluster.cluster, aws_sqs_queue.interruption_queue]
}
