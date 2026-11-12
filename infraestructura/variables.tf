variable "region" {
  type    = string
  default = "us-east-1"
}

variable "nombre_bucket" {
  type    = string
  default = "de-gr01-user-4-entregas-20261112"
}

variable "nombre_base_datos" {
  type    = string
  default = "entregas_db_gr01_user4"
}

variable "nombre_tabla" {
  type    = string
  default = "entregas"
}

variable "nombre_workgroup" {
  type    = string
  default = "wg-entregas-gr01-user4"
}