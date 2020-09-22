#!/bin/bash
set -euxo pipefail # make bash quit if something weird happens

export KUBE_NAMESPACE=${ENVIRONMENT}
export KUBE_SERVER=${KUBE_SERVER}

if [[ -z ${VERSION} ]] ; then
    export VERSION=${IMAGE_VERSION}
fi

if [[ ${ENVIRONMENT} == "cs-prod" ]] ; then
    echo "deploy ${VERSION} to PROD namespace, using HOCS_AUDIT_CS_PROD drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_CS_PROD}
    export REPLICAS="2"
elif [[ ${ENVIRONMENT} == "wcs-prod" ]] ; then
    echo "deploy ${VERSION} to PROD namespace, using HOCS_AUDIT_WCS_PROD drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_WCS_PROD}
    export REPLICAS="2"
elif [[ ${ENVIRONMENT} == "cs-qa" ]] ; then
    echo "deploy ${VERSION} to QA namespace, using HOCS_AUDIT_CS_QA drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_CS_QA}
    export REPLICAS="2"
elif [[ ${ENVIRONMENT} == "wcs-qa" ]] ; then
    echo "deploy ${VERSION} to QA namespace, using HOCS_AUDIT_WCS_QA drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_WCS_QA}
    export REPLICAS="2"
elif [[ ${ENVIRONMENT} == "cs-demo" ]] ; then
    echo "deploy ${VERSION} to DEMO namespace, using HOCS_AUDIT_CS_DEMO drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_CS_DEMO}
    export REPLICAS="1"
elif [[ ${ENVIRONMENT} == "wcs-demo" ]] ; then
    echo "deploy ${VERSION} to DEMO namespace, using HOCS_AUDIT_WCS_DEMO drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_WCS_DEMO}
    export REPLICAS="1"
elif [[ ${ENVIRONMENT} == "cs-dev" ]] ; then
    echo "deploy ${VERSION} to DEV namespace, using HOCS_AUDIT_CS_DEV drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_CS_DEV}
    export REPLICAS="1"
    export DOMAIN="dev.internal.cs"
elif [[ ${ENVIRONMENT} == "wcs-dev" ]] ; then
    echo "deploy ${VERSION} to DEV namespace, using HOCS_AUDIT_WCS_DEV drone secret"
    export KUBE_TOKEN=${HOCS_AUDIT_WCS_DEV}
    export REPLICAS="1"
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
