## Howto

TODO: write me!

### Packer

```sh
cd packer
packer build docker.json
aws ec2 describe-images --owners self --query 'Images[].{id: ImageId, name: Name}' --output table
```
