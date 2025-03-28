locals {
  ##
  # Variables used across multiple areas
  ##
  app_url = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"

  app_port = 5000

  ##
  # Variables used by certificate validation, as part of the load balancer listener, cert and route 53 record configuration
  ##
  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain_name_main   = [for k, v in local.domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  domain_name_sub    = [for k, v in local.domain_types : v.name if k == local.app_url]
  domain_record_main = [for k, v in local.domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  domain_record_sub  = [for k, v in local.domain_types : v.record if k == local.app_url]
  domain_type_main   = [for k, v in local.domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  domain_type_sub    = [for k, v in local.domain_types : v.type if k == local.app_url]

  domain_name_prod   = [for k, v in local.domain_types : v.name if k == "helpdesk.jitbit.dev.cr.probation.service.justice.gov.uk"]
  domain_record_prod = [for k, v in local.domain_types : v.record if k == "helpdesk.jitbit.dev.cr.probation.service.justice.gov.uk"]
  domain_type_prod   = [for k, v in local.domain_types : v.type if k == "helpdesk.jitbit.dev.cr.probation.service.justice.gov.uk"]
  on_prem_dgw_name   = "OnPremiseDataGateway-${local.application_name}-${local.environment}"
}
