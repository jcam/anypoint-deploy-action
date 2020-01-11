#!/bin/bash -l
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

if [[ "${ENVIRONMENT}" = "dev" ]]; then
    ANYPOINT_ENVIRONMENT="Sandbox"
    TARGET_FABRIC="mule-dev-us-west-2"
elif [[ "${ENVIRONMENT}" = "qa" ]]; then
    ANYPOINT_ENVIRONMENT="QA"
    TARGET_FABRIC="mule-qa-us-east-1"
elif [[ "${ENVIRONMENT}" = "prod" ]]; then
    ANYPOINT_ENVIRONMENT="Production"
    TARGET_FABRIC="mule-prod-us-east-1"
fi

GIT_REPO=${GITHUB_REPOSITORY##*/}
ANYPOINT_LAYER=${GIT_REPO%%-*}
ANYPOINT_LAYER=${ANYPOINT_LAYER//sys/System}
ANYPOINT_LAYER=${ANYPOINT_LAYER//proc/Process}
ANYPOINT_LAYER=${ANYPOINT_LAYER//exp/Experience}
APP_NAME=${GIT_REPO##*api-}
ANYPOINT_LAYER_LOWERCASE=$(echo $ANYPOINT_LAYER | tr '[:upper:]' '[:lower:]')
ANYPOINT_ASSET_ID=$APP_NAME-$ANYPOINT_LAYER_LOWERCASE-api
GIT_SHORTSHA=${GITHUB_SHA::8}

#==========================================================
# The branch name is added to the APP name if not 
# the master branch.
#
if [[ -z "$API_INSTANCE_LABEL" ]]; then
    API_INSTANCE_LABEL=${GITHUB_REF##*/}
    API_INSTANCE_LABEL=${API_INSTANCE_LABEL##*-}
    if [[ $API_INSTANCE_LABEL != "master" ]]; then
        APP_NAME_SUFFIX=-$API_INSTANCE_LABEL
    fi
fi
ANYPOINT_APPLICATION_NAME=$GIT_REPO-$API_RELEASE$APP_NAME_SUFFIX
ANYPOINT_APPLICATION_PATH=$APP_NAME$APP_NAME_SUFFIX/$API_RELEASE

#==========================================================
# Build the JAR using Maven
#
mvn -B -s/m2_settings.xml package -DskipTests -Drevision=$API_VERSION-R$GIT_SHORTSHA
mvn -B -s/m2_settings.xml deploy -DskipTests -Drevision=$API_VERSION-R$GIT_SHORTSHA || echo Upload Failed

#==========================================================
# Deploy to runtime fabric
# 
mvn_deploy_cmd="mvn -B -s/m2_settings.xml deploy -DmuleDeploy -DskipTests -Drevision=$API_VERSION-R$GIT_SHORTSHA"
mvn_deploy_cmd+=" -Ddeployment.skipVerification=true"
mvn_deploy_cmd+=" -Dmule.env=$ENVIRONMENT"
mvn_deploy_cmd+=" -Ddeployment.environment=$ANYPOINT_ENVIRONMENT"
mvn_deploy_cmd+=" -Ddeployment.target=$TARGET_FABRIC"
mvn_deploy_cmd+=" -Dapp.name=${ANYPOINT_APPLICATION_NAME::42}"
mvn_deploy_cmd+=" -Dapp.path=${ANYPOINT_APPLICATION_PATH}"
mvn_deploy_cmd+=" -Dhost.external=api.${DOMAIN}"
mvn_deploy_cmd+=" -Dhost.internal=api.internal.${DOMAIN}"
mvn_deploy_cmd+=" -Danypoint.platform.config.analytics.agent.enabled=true"
mvn_deploy_cmd+=" -Danypoint.platform.visualizer.layer=$ANYPOINT_LAYER"
if [[ ! -z "$API_ID" ]]; then
    mvn_deploy_cmd+=" -DapiId=$API_ID"
fi

if [[ "$ANYPOINT_ENVIRONMENT" = "Production" ]]; then
    mvn_deploy_cmd+=" -Ddeployment.replicas=2"
fi
echo $mvn_deploy_cmd
eval $mvn_deploy_cmd
