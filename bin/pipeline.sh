#!/usr/bin/env bash
set -e

cf-mgmt generate-concourse-pipeline

# use modern substitutions
sed -i .bak 's#{{#((#' pipeline.yml
sed -i .bak 's#\}\}#\)\)#' pipeline.yml

# fill in variables
sed -i .bak "s#<your git repo uri>#${GIT_REPO_URI}#" vars.yml
sed -i .bak "s#<your cf system domain>#${SYSTEM_DOMAIN}#" vars.yml
sed -i .bak "s#<user account with permission to create orgs/spaces>#${PCF_USER}#" vars.yml
sed -i .bak "s#<password of user account with permission to create orgs/spaces>#${PCF_PASSWORD}#" vars.yml
sed -i .bak "s#<client secret for uaac for user_id>#${CLIENT_SECRET}#" vars.yml
sed -i .bak "s#<password to bind to ldap>#${LDAP_PASSWORD}#" vars.yml

# send the pipeline to concourse
fly -t ${CONCOURSE_TARGET} set-pipeline -p cf-mgmt -c pipeline.yml --load-vars-from=vars.yml
