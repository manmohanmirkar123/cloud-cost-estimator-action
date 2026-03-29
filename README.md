# Cloud Cost Estimator

[![Actions status](https://github.com/manmohanmirkar/cloud-cost-estimator-action/actions/workflows/test.yml/badge.svg)](https://github.com/manmohanmirkar/cloud-cost-estimator-action/actions/workflows/test.yml)
[![Version](https://img.shields.io/github/v/release/manmohanmirkar/cloud-cost-estimator-action?label=version)](https://github.com/manmohanmirkar/cloud-cost-estimator-action/releases/latest)
[![License](https://img.shields.io/github/license/manmohanmirkar/cloud-cost-estimator-action?label=license)](LICENSE)

Estimate monthly cloud resource costs directly from your IaC code (Terraform, CloudFormation) for **AWS**, **GCP**, and **Azure**.

Powered by [Infracost](https://infracost.io) – open-source & accurate pricing data.

## 📊 Features

- Supports Terraform (.tf) and CloudFormation (.json/.yaml).
- Real-time cost estimates during PRs/CI.
- JSON/HTML outputs for Slack/Jira integrations.
- No setup – Docker container bundles everything.

## 🎯 Usage

### Basic Example (AWS Terraform)

```yaml
name: IaC Cost Check
on: [pull_request]

jobs:
  cost:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Estimate Costs
        id: cost
        uses: manmohanmirkar/cloud-cost-estimator-action@v1.0.0  # or ./ for local
        with:
          iac-path: ./terraform
          provider: aws
      - name: Show Cost
        run: echo "Monthly cost: ${{ steps.cost.outputs.total-monthly-cost }}"
```

### Outputs

| Output               | Type   | Description             |
| -------------------- | ------ | ----------------------- |
| `total-monthly-cost` | string | e.g. "127.50" (USD)     |
| `breakdown`          | JSON   | Full resource breakdown |
| `report`             | string | Path to HTML report     |

## ⛅️ Providers

- **AWS**: EC2, RDS, S3, Lambda...
- **GCP**: Compute, CloudSQL, Storage...
- **Azure**: VM, CosmosDB, Storage...

## 🏪 Publish to GitHub Marketplace

1. Push & tag: `git tag v1.0.0 && git push --tags`
2. Create [Release](https://github.com/manmohanmirkar/cloud-cost-estimator-action/releases)
3. Click **"Publish to GitHub Marketplace"** → Approved in days!

## 🔧 Local Testing

```bash
brew install act
act workflow_dispatch -j test
```

Docker image: `ghcr.io/manmohanmirkar/cloud-cost-estimator-action:main`

## 🤝 Contributing

See CONTRIBUTING.md

## 📄 License

MIT

```
</xai:function_call name="edit_file">
<parameter name="path">/Users/manmohanmirkar/github-custom-actions/TODO.md
```
