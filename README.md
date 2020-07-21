# AWS DevOps Test

This repository will use Terraform to deploy a simple todo React application that has been made by myself and can be found here: https://github.com/Noatz/todo.

## How To

### Deploy

A helper script has been made to assist the use of continuously typing out Terraform commands. This helper script currently accepts the following commands:

#### `init`

```bash
# tf.sh PROFILE S3-BUCKET
./tf.sh init personal terraform-j38sj2s3w
```

#### `plan`

```bash
./tf.sh plan
```

#### `apply`

```bash
./tf.sh apply
```

#### `destroy`

```bash
./tf.sh destroy
```

## Q&A

**How would you provide shell access into the application stack for operations staff who may want to log into an instance?** Given that the instances are all running in private subnets, ssh cannot be used. Fortunately, the ami that I am using comes with the ssm agent installed and therefore I would ask staff to utilise the awscli tool with credentials given by an admin.

**Make access and error logs available in CloudWatch Logs?** I would find and use an npm package (e.g. https://www.npmjs.com/package/aws-cloudwatch-log) to push logs from my React app to a CloudWatch Log Group. To further improve this setup and make use of these logs, I would create a metric filter for ERROR logs and create an CloudWatch Alarm to send me a notificatino via SNS.

## Problems & Help

- Terraform currently is unable to delete a VPC as it can't delete all its dependencies.

## Further Thoughts

Given more time I would:

- Utilise ACM to create a secure SSL route.
