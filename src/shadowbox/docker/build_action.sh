#!/bin/bash -eu
#
# Copyright 2018 The Outline Authors
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

export DOCKER_CONTENT_TRUST=${DOCKER_CONTENT_TRUST:-1}
# Enable Docker BuildKit (https://docs.docker.com/develop/develop-images/build_enhancements)
# TODO(fortuna): Re-enable after we figure out how to make it work on Travis.
# export DOCKER_BUILDKIT=1
docker build --force-rm --build-arg GITHUB_RELEASE="${TRAVIS_TAG:-none}" -t ${SB_IMAGE:-outline/shadowbox} $ROOT_DIR -f src/shadowbox/docker/Dockerfile
