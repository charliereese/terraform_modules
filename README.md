## Overview

This repository contains terraform modules for use in various web applications.

## Usage

Terraform modules can be referenced like so:

```
module "webserver_cluster" {
  source = "github.com/charliereese/terraform_modules/webserver-cluster?ref=v0.0.1"
  cluster_name  = "webservers-staging"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}
```

Note that variables without default values (like min_size above), as well as any variables you wish to override, must be specified in the module block below source.
