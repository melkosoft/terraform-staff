variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}
variable "AWS_DEFAULT_REGION" {}

# Available ENV variables
# SG_FILTER_TYPE =     '', 'vpc', 'tag'. default: missing(empty) - monitor ALL security groups
#                      'vpc' - SG_FILTER_VALUE include list of VPC ids separated by comma
#                      'tag' - SG_FILTER_KEY has tag name to check, SG_FILTER_VALUE - list of values
#                      'groupid' - SG_FILTER_VALUE include list of security group ids separated by comma
# SG_FILTER_KEY        security groups tag name to monitor 
# SG_FILTER_VALUE      security groups tag values 
variable "sg_notify_lambda_env" {
  type = "map"
  default = {
    RCPT_TO = "mamaenko@hp.com"
    MAIL_FROM = "mamaenko@hp.com"
  }
}


# Available ENV variables
# RT_FILTER_TYPE =     '', 'routetableid','vpc','tag', default: '', monitor ALL RouteTable changes
# RT_FILTER_KEY
# RT_FILTER_VALUE
variable "rt_notify_lambda_env" {
  type = "map"
  default = {
    RCPT_TO = "mamaenko@hp.com"
    MAIL_FROM = "mamaenko@hp.com"
  }
}

variable "sg_notify_func_name" {
  default = "sg_notify"
}

variable "rt_notify_func_name" {
  default = "rt_notify"
}
