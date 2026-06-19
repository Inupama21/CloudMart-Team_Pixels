variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version; null uses the AWS default"
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Private application subnets for EKS nodes and control-plane ENIs"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Supplemental security group for worker nodes"
  type        = string
}

variable "endpoint_public_access" {
  description = "Keep the EKS public API endpoint available for GitHub Actions"
  type        = bool
  default     = true
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs allowed to reach the EKS public API"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Allowed instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "node_disk_size_gib" {
  type    = number
  default = 30
}

variable "control_plane_log_retention_days" {
  type    = number
  default = 30
}

variable "common_tags" {
  description = "Tags applied to EKS resources"
  type        = map(string)
  default     = {}
}

variable "cicd_role_arn" {
  description = "GitHub Actions role granted cluster administration for controllers and deployments"
  type        = string
  default     = null
}
