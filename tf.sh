#!/bin/bash

terraform init -backend=true \
        -backend-config="profile=personal" \
        -backend-config="bucket=terraform-j38sj2s3w"
