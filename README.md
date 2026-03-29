# Cloud Cost Estimator

[![Actions status](https://github.com/manmohanmirkar123/cloud-cost-estimator-action/actions/workflows/test.yml/badge.svg)](https://github.com/manmohanmirkar123/cloud-cost-estimator-action/actions/workflows/test.yml)
[![Version](https://img.shields.io/github/v/release/manmohanmirkar123/cloud-cost-estimator-action?label=version)](https://github.com/manmohanmirkar123/cloud-cost-estimator-action/releases/latest)
[![License](https://img.shields.io/github/license/manmohanmirkar123/cloud-cost-estimator-action?label=license)](LICENSE)

Estimate monthly cloud resource costs directly from your IaC code (Terraform, CloudFormation) for **AWS**, **GCP**, and **Azure**.

Powered by [Infracost](https://infracost.io) – open-source & accurate pricing data.

## 📊 Features

- Supports Terraform (.tf) and CloudFormation (.json/.yaml).
- Real-time cost estimates during PRs/CI.
- Pull request comment updates with the latest cost summary.
- JSON and readable text report outputs.
- No setup – the action installs Terraform and Infracost at runtime.

## 🔑 Setup

Before using this action, create an Infracost API key and store it as a GitHub Actions secret. The API key is available with Infracost's free plan:

1. Sign in to [Infracost](https://www.infracost.io) and create or copy your API key from your account/dashboard.
2. In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions**.
3. Create a new repository secret named `INFRACOST_API_KEY`.
4. Reference it in your workflow as `${{ secrets.INFRACOST_API_KEY }}`.

Do not hardcode the API key directly in your workflow file or commit it to the repository.

## 🎯 Usage

### Basic Example (AWS Terraform)

```yaml
name: IaC Cost Check
on: [pull_request]

jobs:
  cost:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Estimate Costs
        id: cost
        uses: manmohanmirkar123/cloud-cost-estimator-action@v1.0.0  # or ./ for local
        with:
          iac-path: ./terraform
          provider: aws
          infracost-api-key: ${{ secrets.INFRACOST_API_KEY }}
      - name: Show Cost
        run: echo "Monthly cost: ${{ steps.cost.outputs.total-monthly-cost }}"
```

This action can also create or update a pull request comment automatically. Set `comment-on-pr: 'false'` if you only want outputs.
It can also upload the generated reports to the GitHub Actions UI as a downloadable artifact.

### Inputs

| Input | Required | Description |
| ----- | -------- | ----------- |
| `iac-path` | Yes | Path to the Terraform or CloudFormation directory |
| `provider` | Yes | Cloud provider: `aws`, `gcp`, or `azure` |
| `infracost-api-key` | Yes | Infracost API key used for pricing lookup |
| `github-token` | No | GitHub token for PR comments, defaults to `${{ github.token }}` |
| `comment-on-pr` | No | `true` to create/update a PR comment, defaults to `true` |
| `upload-report-artifact` | No | `true` to upload report files to the Actions UI, defaults to `true` |
| `artifact-name` | No | Artifact name shown in the GitHub Actions UI |

### Outputs

| Output               | Type   | Description             |
| -------------------- | ------ | ----------------------- |
| `total-monthly-cost` | string | e.g. "127.50" (USD)     |
| `breakdown`          | JSON   | Full resource breakdown |
| `report`             | string | Path to generated report |
| `report-json`        | string | Path to generated JSON report |

### Pull Request Example

```yaml
name: IaC Cost Check
on:
  pull_request:

jobs:
  cost:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v6
      - uses: manmohanmirkar123/cloud-cost-estimator-action@v1.0.0
        with:
          iac-path: examples/terraform-aws
          provider: aws
          infracost-api-key: ${{ secrets.INFRACOST_API_KEY }}
```

The workflow run will then show a downloadable artifact such as `cloud-cost-report` in the GitHub Actions UI.

## ⛅️ Providers

- **AWS**: EC2, RDS, S3, Lambda...
- **GCP**: Compute, CloudSQL, Storage...
- **Azure**: VM, CosmosDB, Storage...

## 🏪 Publish to GitHub Marketplace

1. Push & tag: `git tag v1.0.0 && git push --tags`
2. Create [Release](https://github.com/manmohanmirkar123/cloud-cost-estimator-action/releases)
3. Click **"Publish to GitHub Marketplace"** → Approved in days!

## 🔧 Local Testing

```bash
brew install act
mkdir -p /tmp/act-artifacts
act workflow_dispatch -j test \
  --container-architecture linux/amd64 \
  --artifact-server-path /tmp/act-artifacts \
  --artifact-server-addr 127.0.0.1 \
  --cache-server-addr 127.0.0.1 \
  -s INFRACOST_API_KEY=your_key_here
```

You can also run the entrypoint directly in a Linux container if you want to debug the script itself:

```bash
docker run --rm -it \
  -v "$PWD":/work \
  -w /work \
  -e GITHUB_WORKSPACE=/work \
  -e GITHUB_OUTPUT=/tmp/github_output \
  -e IAC_PATH=examples/terraform-aws \
  -e PROVIDER=aws \
  ubuntu:22.04 \
  bash -lc './entrypoint.sh && cat /tmp/github_output'
```

Docker image: `ghcr.io/manmohanmirkar/cloud-cost-estimator-action:main`

## 🤝 Contributing

See CONTRIBUTING.md

## 📄 License

MIT
