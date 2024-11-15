# Amazon ECS running on FARGATE with CI/CD

## Provisioning with OpenTofu

Execute:

```sh
tofu init
tofu plan --var-file variables.tfvars
tofu apply --var-file variables.tfvars  
```