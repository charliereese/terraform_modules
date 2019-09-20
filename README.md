## Overview

This repository contains terraform modules for use in various web applications.

## Usage

Terraform modules can be referenced like so:

```
module "webserver_cluster" {
  source = "github.com/charliereese/terraform_modules//web_servers?ref=v0.0.1"

  ami                 = "ami-0c55b159cbfafe1f0"
  cluster_name        = "site-staging"
  domain_name         = "site.com"
  min_size            = 1
  max_size            = 1
  business_hours_size = 1
  night_hours_size    = 1
}
```

Note: variables without default values (like min_size above), as well as any variables you wish to override, must be specified in the module block below source.

Note: Most modules were introduced after v0.0.1. 