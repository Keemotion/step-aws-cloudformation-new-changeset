# aws cloudformation

A wercker step to create CloudFormation changesets.

## Example Usage

In your [wercker.yml](http://devcenter.wercker.com/articles/werckeryml/) file under the `deploy` section:

``` yaml
deploy:
  steps:
    - create-changeset:
        template_path: "mydir/stack.yml"
        stack: my_cf_stack
```

## Options

* `wait` (optional) Determines whether to wait until the task is complete
* `aws_access_key_id` (optional)
* `aws_secret_access_key` (optional)
* `region` (optional, default: `"us-east-1"`)
* `stack` (required)
* `changeset` (optional, default: `"wercker-$WERCKER_BUILD_ID"`)
* `template_path` (required) path to the cloudformation stack file to deploy
* `parameters` (optional) They have to be specified as one or more key-value
   pairs, with multiple values separated by a space. Like so:
   "ParameterKey=InstanceType,ParameterValue=m3.large
   ParameterKey=ClusterSize,ParameterValue=3"
* `capabilities` (optional) Can be used for instance when creating IAM roles.
   You need to specify that it's allowed (set the value to "CAPABILITY_IAM"`).

# Changelog

## 0.1.0

- Initial release
