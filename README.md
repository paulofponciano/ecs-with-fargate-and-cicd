![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)

# Amazon ECS running on FARGATE with CI/CD

## Provisioning with OpenTofu

Execute:

```sh
tofu init
tofu plan --var-file variables.tfvars
tofu apply --var-file variables.tfvars
```

---