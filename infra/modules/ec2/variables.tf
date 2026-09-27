# modules/ec2/variables.tf

variable "instance_name" {
  description = "Nome da instancia EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instancia"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID para a instancia"
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde a instancia sera criada"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de Security Group IDs"
  type        = list(string)
}

variable "key_name" {
  description = "Nome do key pair para SSH (opcional)"
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  description = "Instance profile (ex: LabInstanceProfile no AWS Academy)"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script (opcional)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}