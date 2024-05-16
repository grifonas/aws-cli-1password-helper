# AWS CLI 1Password Integration Script

This script allows you to manage AWS credentials stored in 1Password and use them with the AWS CLI. It provides two main functionalities:

1. Allows the AWS CLI to source credentials directly from 1Password.
2. Manages your `~/.aws/credentials` and `~/.aws/config` files based on items stored in 1Password.

## Prerequisites

- AWS CLI
- 1Password CLI (`op`)
- `jq` for JSON processing

# Usage
- Prepare your 1Password items
- Install and run

## Prepare Your 1Password Item Structure

Your 1Password items must contain the following fields and tags:

### Fields:
**Required**:
- `access key id`
- `secret access key`
- `aws-cli-profile`
**Optional**:
- `default-region`

### Tags:
- `aws_cred_for_sourcing`

## Installation

- Make sure the script is in your `${PATH}`.
- Run this script with the 'build_awc_cli_cred_file' argument:

   ```bash
   ./aws-cred-getter.sh build_awc_cli_cred_file
   ```

   This will prepare your `~/.aws/credentials` and `~/.aws/config`.
   This command can be run every time you add a new AWS cred. pair to your 1Password.


