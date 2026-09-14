# Security Policy

## Supported Versions

Security fixes are applied to the latest version on the default branch.

## Reporting a Vulnerability

Do not open a public issue for a vulnerability that could expose credentials,
state data, output values, or command execution details.

Use GitHub's private vulnerability reporting feature for this repository. If it
is unavailable, contact the repository owner through the email address listed on
their GitHub profile.

Include the affected version, reproduction steps, impact, and any suggested
mitigation. Remove credentials, Terraform state, and sensitive output values
from reports and logs.

## Scope

Relevant reports include shell injection, unsafe parsing of Terragrunt output,
leakage of sensitive output values, insecure cache permissions, and unintended
state-changing commands triggered by completion.
