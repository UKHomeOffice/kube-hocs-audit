#!/bin/bash
set -euxo pipefail # make bash quit if something weird happens

export KUBE_NAMESPACE=${ENVIRONMENT}
export KUBE_SERVER=${KUBE_SERVER}

if [[ -z ${VERSION} ]] ; then
    export VERSION=${IMAGE_VERSION}
fi

if [[ ${KUBE_NAMESPACE} == *prod ]]
then
    export MIN_REPLICAS="2"
    export MAX_REPLICAS="8"
else
    export MIN_REPLICAS="1"
    export MAX_REPLICAS="2"
fi

# passed to keycloak-gatekeeper and nginx for various proxy timeouts
# the default is 60 seconds but audit has long-running queries
export PROXY_TIMEOUT="300"

if [[ ${ENVIRONMENT} == "cs-prod" ]] ; then
    echo "deploy ${VERSION} to PROD namespace, using HOCS_AUDIT_CS_PROD drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_CS_PROD}
elif [[ ${ENVIRONMENT} == "wcs-prod" ]] ; then
    echo "deploy ${VERSION} to PROD namespace, using HOCS_AUDIT_WCS_PROD drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_WCS_PROD}
elif [[ ${ENVIRONMENT} == "cs-qa" ]] ; then
    echo "deploy ${VERSION} to QA namespace, using HOCS_AUDIT_CS_QA drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_CS_QA}
elif [[ ${ENVIRONMENT} == "wcs-qa" ]] ; then
    echo "deploy ${VERSION} to QA namespace, using HOCS_AUDIT_WCS_QA drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_WCS_QA}
elif [[ ${ENVIRONMENT} == "cs-demo" ]] ; then
    echo "deploy ${VERSION} to DEMO namespace, using HOCS_AUDIT_CS_DEMO drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_CS_DEMO}
elif [[ ${ENVIRONMENT} == "wcs-demo" ]] ; then
    echo "deploy ${VERSION} to DEMO namespace, using HOCS_AUDIT_WCS_DEMO drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_WCS_DEMO}
elif [[ ${ENVIRONMENT} == "cs-dev" ]] ; then
    echo "deploy ${VERSION} to DEV namespace, using HOCS_AUDIT_CS_DEV drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_CS_DEV}
    export DOMAIN="dev.internal.cs"
elif [[ ${ENVIRONMENT} == "wcs-dev" ]] ; then
    echo "deploy ${VERSION} to DEV namespace, using HOCS_AUDIT_WCS_DEV drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_WCS_DEV}
    export DOMAIN="dev.wcs"
else
    echo "Unable to find environment: ${ENVIRONMENT}"
fi

if [[ -z ${KUBE_TOKEN} ]] ; then
    echo "Failed to find a value for KUBE_TOKEN - exiting"
    exit -1
fi

if [[ "${ENVIRONMENT}" == "wcs-prod" ]] ; then
    export DNS_PREFIX=www.${DOMAIN}
    export KC_REALM=https://sso.digital.homeoffice.gov.uk/auth/realms/HOCS
elif [[ "${ENVIRONMENT}" == "cs-prod" ]] ; then
    export DNS_PREFIX=www.${DOMAIN}
    export KC_REALM=https://sso.digital.homeoffice.gov.uk/auth/realms/hocs-prod
else
    export DNS_PREFIX=${DOMAIN}-notprod
    export KC_REALM=https://sso-dev.notprod.homeoffice.gov.uk/auth/realms/hocs-notprod
fi

 export DOMAIN_NAME=${DNS_PREFIX}.homeoffice.gov.uk	

echo	
echo "Deploying audit to ${ENVIRONMENT}"
echo "Keycloak realm: ${KC_REALM}"
echo "Redirect URL: ${DOMAIN_NAME}"
echo

cd kd

kd --insecure-skip-tls-verify \
   --timeout 10m \
    -f deployment.yaml \
    -f service.yaml \
    -f autoscale.yaml
