#!/bin/bash -eu
#
# Copyright 2024 The Outline Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -eu

SCRIPT_DIR="$(dirname "$0")"
PROJECT_DIR="${BUILD_DIR}/server_manager/electron_app/static"
BUILD_MODE=debug
PLATFORM= 

function package_electron() {
  declare -a electron_builder_cmd=(
    electron-builder
    --projectDir="${PROJECT_DIR}"
    --config="${SCRIPT_DIR}/electron_builder.json"
    --publish=never
  )

  case "${PLATFORM}" in
    linux)
      electron_builder_cmd+=(--linux);;
    windows)
      electron_builder_cmd+=(--win --ia32);;
    macos)
      electron_builder_cmd+=(--mac);;
    *)
      echo "Unsupported platform ${PLATFORM}" >&2 && exit 1
  esac

  if [[ "${BUILD_MODE}" == "release" ]]; then
    electron_builder_cmd+=(
      --config.generateUpdatesFilesForAllChannels=true
      --config.publish.provider=generic
      --config.publish.url=https://s3.amazonaws.com/outline-releases/manager/
    )
  fi

  "${electron_builder_cmd[@]}"
}

function finish_yaml_files() {
  declare -r STAGING_PERCENTAGE="${1?Staging percentage missing}"

  RELEASE_CHANNEL=$(node_modules/node-jq/bin/jq -r '.version' src/server_manager/package.json | cut -s -d'-' -f2)
  # If this isn't an alpha or beta build, `cut -s` will return an empty string
  if [[ -z "${RELEASE_CHANNEL}" ]]; then
    RELEASE_CHANNEL=latest
  fi
  echo "stagingPercentage: ${STAGING_PERCENTAGE}" >> "${PROJECT_DIR}/dist/${RELEASE_CHANNEL}${PLATFORM}.yml"

  # If we cut a staged mainline release, beta testers will take the update as well.
  if [[ "${RELEASE_CHANNEL}" == "latest" ]]; then
    echo "stagingPercentage: ${STAGING_PERCENTAGE}" >> "${PROJECT_DIR}/dist/beta${PLATFORM}.yml"
  fi

  # We don't support alpha releases
  rm -f "${PROJECT_DIR}/dist/alpha${PLATFORM}.yml"
}

function main() {
  declare staging_percentage=100
  declare version_name='0.0.0-debug'
  for i in "$@"; do
    case "${i}" in
    --buildMode=*)
      BUILD_MODE="${i#*=}"
      shift
      ;;
    --versionName=*)
      version_name="${i#*=}"
      shift
      ;;
    --stagingPercentage=*)
      staging_percentage="${i#*=}"
      shift
      ;;
    --* | -*)
      echo "Unknown option: ${i}"
      exit 1
      ;;
    *) ;;
    esac
  done
  PLATFORM="${1?Platform missing}"
  run_action server_manager/electron_app/build --buildMode="${BUILD_MODE}" --versionName="${version_name}"
  package_electron
  finish_yaml_files "${staging_percentage}"
}

main "$@"