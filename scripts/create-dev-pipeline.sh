
#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
FLY_TARGET=${FLY_TARGET:-$ATC_URL}
FLY_CMD=${FLY_CMD:-fly}

env=${DEPLOY_ENV:-$1}
pipeline="dev"
config="${SCRIPT_DIR}/../pipelines/dev.yml"

[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100

generate_vars_file() {
   set -u # Treat unset variables as an error when substituting
	 PRIVATE_KEY="$(cat ~/.ssh/id_rsa | sed 's/^/  /')"
   cat <<EOF
---
private_key: |
${PRIVATE_KEY}
EOF
}

generate_vars_file #> /dev/null # Check for missing vars

bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
   "${env}" "${pipeline}" "${config}" <(generate_vars_file)

$FLY_CMD -t "${FLY_TARGET}" unpause-pipeline --pipeline "${pipeline}"

# Start pipeline
# curl "${ATC_URL}/pipelines/${pipeline}/jobs/init-bucket/builds" -X POST

cat <<EOF
You can watch the last vpc deploy job by running the command below.
You might need to wait a few moments before the latest build starts.

$FLY_CMD -t "${FLY_TARGET}" watch -j "${pipeline}/vpc"
EOF
