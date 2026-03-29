# Task: Fix Cloud Cost Estimator Action Test Failure

## Steps:

- [x] Step 1: Update entrypoint.sh with dependency installations (jq, Terraform, Infracost).
- [x] Step 2: Fix IaC path handling with `${GITHUB_WORKSPACE:-.}` and debug logs.
- [x] Step 3: Improve IaC file detection using `find` instead of `ls` glob.
- [x] Step 4: Test with `rm -rf ./artifacts && act workflow_dispatch -j test --platform linux/amd64`. (Passed IaC detection, failed at TF install)
- [x] Step 5: Fix install with apt repo and latest releases.
- [ ] Step 6: Fix Infracost tar extract with if flat or dir, re-test.
