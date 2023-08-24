#!/bin/bash
export TARGET_DIR=$(pwd)/packages/djangoflow_openapi
export DART_POST_PROCESS_FILE="/usr/local/bin/dartfmt -w"
cd "$(dirname "${BASH_SOURCE[0]}")"/.. || exit
HOST_NAME=${1:-"http://127.0.0.1:8000"}
API_VERSION=${2:-"v1"}

echo "Generating OpenAPI client using host: ${HOST_NAME}"
[ -d "${TARGET_DIR}" ] || mkdir -p "${TARGET_DIR}"
${OPENAPI_GENERATOR:-openapi-generator} generate -g dart-dio -p browserClient=false -p nullableFields=true \
  -p serializationLibrary=json_serializable -p pubName=djangoflow_openapi \
  -p pubLibrary=djangoflow_openapi \
  -i "${HOST_NAME}/api/${API_VERSION}/schema" -o "${TARGET_DIR}" \
  && cd "${TARGET_DIR}" \
  && grep -rl 'includeIfNull: truefalse' lib  | xargs sed -i '' 's/includeIfNull: truefalse/includeIfNull: true/g' \
  && flutter pub get \
  && dart run build_runner build --delete-conflicting-outputs