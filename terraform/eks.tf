# EKS Cluster Configuration
# Runs alongside ECS - both can coexist

# EKS is now the default deployment method
variable "enable_eks" {
  description = "Enable EKS cluster deployment"
  type        = bool
  default     = true
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  count = var.enable_eks ? 1 : 0
  name  = "${local.prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.enable_eks ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  count      = var.enable_eks ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role[0].name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_role" {
  count = var.enable_eks ? 1 : 0
  name  = "${local.prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count      = var.enable_eks ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.enable_eks ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  count      = var.enable_eks ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role[0].name
}

# Security Group for EKS
resource "aws_security_group" "eks_cluster_sg" {
  count       = var.enable_eks ? 1 : 0
  name        = "${local.prefix}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.prefix}-eks-cluster-sg"
  })
}

resource "aws_security_group" "eks_node_sg" {
  count       = var.enable_eks ? 1 : 0
  name        = "${local.prefix}-eks-node-sg"
  description = "Security group for EKS nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow pods to communicate with cluster API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg[0].id]
  }

  ingress {
    description = "Allow worker nodes to communicate with each other"
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.prefix}-eks-node-sg"
  })
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  count    = var.enable_eks ? 1 : 0
  name     = "${local.prefix}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role[0].arn
  version  = "1.31"

  vpc_config {
    subnet_ids              = local.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster_sg[0].id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]

  tags = local.tags
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  count           = var.enable_eks ? 1 : 0
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${local.prefix}-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_role[0].arn
  subnet_ids      = local.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = local.tags
}

# EKS Add-ons
resource "aws_eks_addon" "vpc_cni" {
  count        = var.enable_eks ? 1 : 0
  cluster_name = aws_eks_cluster.main[0].name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "coredns" {
  count        = var.enable_eks ? 1 : 0
  cluster_name = aws_eks_cluster.main[0].name
  addon_name   = "coredns"

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  count        = var.enable_eks ? 1 : 0
  cluster_name = aws_eks_cluster.main[0].name
  addon_name   = "kube-proxy"
}

# OIDC Provider for EKS
data "tls_certificate" "eks" {
  count = var.enable_eks ? 1 : 0
  url   = aws_eks_cluster.main[0].identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  count           = var.enable_eks ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main[0].identity[0].oidc[0].issuer

  tags = local.tags
}
