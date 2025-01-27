#!/bin/bash

set -e
set -o pipefail

TEMP_FILES="$(mktemp -t 2>/dev/null || mktemp -t 'helm_release_files')"

# Export XDG directories to get access to
# helm user defined repos
export XDG_CACHE_HOME={HELM_CACHE_PATH}
export XDG_CONFIG_HOME={HELM_CONFIG_PATH}
export XDG_DATA_HOME={HELM_DATA_PATH}

function read_variables() {
    local file="$1"
    local new_file="$(mktemp -t 2>/dev/null || mktemp -t 'helm_release_new')"
    echo "${new_file}" >> "${TEMP_FILES}"

    # Rewrite the file from Bazel for the form FOO=...
    # to a form suitable for sourcing into bash to expose
    # these variables as substitutions in the tag statements.
    sed -E "s/^([^ ]+) (.*)\$/export \\1='\\2'/g" < ${file} > ${new_file}
    source ${new_file}
}

%{stamp_statements}

export HELM_CHART_VERSION={HELM_CHART_VERSION}
export APP_VERSION={APP_VERSION}

DIGEST_PATH={DIGEST_PATH}
IMAGE_REPOSITORY={IMAGE_REPOSITORY}
IMAGE_TAG={IMAGE_TAG}

chmod 777 {CHART_VALUES_PATH}

# If an explicit chart version is not defined, use the value in Chart.yaml.
if [ -z $HELM_CHART_VERSION ]; then
  export HELM_CHART_VERSION=$({YQ_PATH} r {CHART_MANIFEST_PATH} 'version')
fi

# Application docker image is not provided by other docker bazel rule
if  [ -z $DIGEST_PATH ]; then

    # Image repository is provided as a static value
    if [ "$IMAGE_REPOSITORY" != "" ] && [ -n $IMAGE_REPOSITORY ]; then
        {YQ_PATH} w -i {CHART_VALUES_PATH} {VALUES_REPO_YAML_PATH} $IMAGE_REPOSITORY
        echo "Replaced image repository in chart values.yaml with: $IMAGE_REPOSITORY"
    fi

    # Image tag is provided as a static value
    if [ "$IMAGE_TAG" != "" ] && [ -n $IMAGE_TAG ]; then
        {YQ_PATH} w -i {CHART_VALUES_PATH} {VALUES_TAG_YAML_PATH} $IMAGE_TAG
        echo "Replaced image tag in chart values.yaml with: $IMAGE_TAG"
    fi

    if [ -z $APP_VERSION ]; then
      export APP_VERSION=$IMAGE_TAG
    fi

fi

# Application docker image is provided by other docker bazel rule
if [ -n $DIGEST_PATH ] && [ "$DIGEST_PATH" != "" ]; then
    # extracts the digest sha and removes 'sha256' text from it
    DIGEST=$(cat {DIGEST_PATH})
    IFS=':' read -ra digest_split <<< "$DIGEST"
    DIGEST_SHA=${digest_split[1]}

    {YQ_PATH} w -i {CHART_VALUES_PATH} {VALUES_TAG_YAML_PATH} $DIGEST_SHA

    echo "Replaced image tag in chart values.yaml with: $DIGEST_SHA"

    REPO_SUFIX="@sha256"

    if [ -n $IMAGE_REPOSITORY ] && [ "$IMAGE_REPOSITORY" != "" ]; then
        REPO_URL="{IMAGE_REPOSITORY}"
    else
        # if image_repository attr is not provided, extract it from values.yaml
        REPO_URL=$({YQ_PATH} r {CHART_VALUES_PATH} {VALUES_REPO_YAML_PATH})
    fi

    # appends @sha256 suffix to image repo url value if the repository value does not already contains it
    if ([ -n $REPO_URL ] || [ -n $REPO_SUFIX ]) && ([[ $REPO_URL != *"$REPO_SUFIX" ]] || [[ -z "$REPO_SUFIX" ]]); then
        {YQ_PATH} w -i {CHART_VALUES_PATH} {VALUES_REPO_YAML_PATH} ${REPO_URL}${REPO_SUFIX}
    fi

    if [ -z $APP_VERSION ]; then
      export APP_VERSION=$DIGEST_SHA
    fi

fi

#{HELM_PATH} env

# {HELM_PATH} repo list
{HELM_PATH} package {CHART_PATH} --dependency-update --destination {PACKAGE_OUTPUT_PATH} --app-version $APP_VERSION --version $HELM_CHART_VERSION 1>>/dev/null

mv {PACKAGE_OUTPUT_PATH}/{HELM_CHART_NAME}-$HELM_CHART_VERSION.tgz {PACKAGE_OUTPUT_PATH}/{HELM_CHART_NAME}.tgz

rm -rf {CHART_PATH}

echo "Successfully packaged chart and saved it to: {PACKAGE_OUTPUT_PATH}/{HELM_CHART_NAME}.tgz"
