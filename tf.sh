#!/bin/bash

PROFILE=$2
S3_BUCKET=$3
VAR_FILE=terraform.tfvars
OUT_FILE=tf.out


init() {
    terraform init -backend=true \
        -backend-config="profile=$PROFILE" \
        -backend-config="bucket=$S3_BUCKET"
}

plan() {
    terraform plan -var-file=$VAR_FILE -out=$OUT_FILE
}

apply() {
    terraform apply $OUT_FILE
}

destroy() {
    terraform destroy
}


# make sure there are 3 args if running the `init` command
[[ $1 == 'init' && -z $3 ]] && \
    echo "Please supply a PROFILE and S3_BUCKET" && exit

$1
