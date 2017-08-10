#!/usr/bin/env bash
BASEDIR=`dirname $0`
cf-mgmt init-config

# allow for organizations for the entire navy and each ship with spaces for development regions

# Navy wide applications
cf-mgmt add-org-to-config --org navy --org-billing-mgr-grp gentry --org-auditor-grp captain
cf-mgmt add-space-to-config --org navy --space production --space-mgr-grp captains --space-auditor-grp midshipman
cf-mgmt add-space-to-config --org navy --space integration --space-mgr-grp lieutenants --space-auditor-grp sailors
cf-mgmt add-space-to-config --org navy --space development --space-mgr-grp crew --space-dev-grp sailors

# HMS Victory applications
cf-mgmt add-org-to-config --org victory --org-billing-mgr-grp gentry --org-auditor-grp "HMS Victory"
cf-mgmt add-space-to-config --org victory --space production --space-mgr-grp captains --space-auditor-grp "HMS Victory"
cf-mgmt add-space-to-config --org victory --space integration --space-mgr-grp lieutenants --space-auditor-grp "HMS Victory"
cf-mgmt add-space-to-config --org victory --space development --space-mgr-grp crew --space-dev-grp "HMS Victory"

# HMS Bounty applications
cf-mgmt add-org-to-config --org bounty --org-billing-mgr-grp gentry --org-auditor-grp "HMS Bounty"
cf-mgmt add-space-to-config --org bounty --space production --space-mgr-grp captains --space-auditor-grp "HMS Bounty"
cf-mgmt add-space-to-config --org bounty --space integration --space-mgr-grp lieutenants --space-auditor-grp "HMS Bounty"
cf-mgmt add-space-to-config --org bounty --space development --space-mgr-grp crew --space-dev-grp "HMS Bounty"

# HMS Lydia applications
cf-mgmt add-org-to-config --org lydia --org-billing-mgr-grp gentry --org-auditor-grp "HMS Lydia"
cf-mgmt add-space-to-config --org lydia --space production --space-mgr-grp captains --space-auditor-grp "HMS Lydia"
cf-mgmt add-space-to-config --org lydia --space integration --space-mgr-grp lieutenants --space-auditor-grp "HMS Lydia"
cf-mgmt add-space-to-config --org lydia --space development --space-mgr-grp crew --space-dev-grp "HMS Lydia"

git add config
git commit -m "Added various orgs and spaces"
git push --set-upstream origin demo
