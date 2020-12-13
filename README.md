# Sample terraform code to create AWS basic infra and EKS within

## Initialize

First in [aws-environment](./aws-environment), initialize terraform by something like:
```
terraform init \
  -backend-config="bucket=MYBUCKET" \
  -backend-config="key=MYKEY" \
  -backend-config="region=MYREGION" \
  -backend-config="profile=MYPROFILE" 
```
## Prepare the environment

Set the terraform variables you want to override. Mandatory ones:
```
export TF_VAR_aws_profile=...
export TF_VAR_aws_region=...
```
Check [variables.tf](./variables.tf) for others.

## Terraforming

Invoke `terraform plan` or `apply` or `destroy` as needed.

## EKS

Repeat the initialization with the appropriate values in [eks](./eks).
*Make sure to use the appropriate `TF_VAR_aws_profile`* esp. if you want to use a different one for EKS maintenance.

Once the cluster is ready, create the bootstrap kubeconfig via:
```
aws --profile CLUSTER_CREATOR_PROFILE  eks update-kubeconfig --name CLUSTER_NAME
```
In this step you *must* use the same profile which was used to create the cluster.
In order to provide `kubectl` access for other AWS users/roles, update the _aws-auth_ configmap.

```
kubectl patch -n kube-system configmap/aws-auth --type merge --patch '{"data": { "mapUsers": "- userarn: arn:aws:iam::$ACCOUNT_ID:user/kube-user\n  username: kube-user\n  groups:\n  - system:masters\n" }}'
```

## external-dns

Check [extra-values](./helm-charts/external-dns/extra-values.yml) for the values to override.
The service (_external-dns_) name must match the _"system:serviceaccount:default:external-dns"_ condition in [serviceaccount.tf](./eks/serviceaccount.tf)



