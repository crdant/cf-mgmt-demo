#!/usr/bin/env bash
set -e

docker run -d -p 0.0.0.0:389:389 --name ldap -t cwashburn/ldap
cf dev start
cf dev ssh <<MODIFY_UAA_YML
sed -i -e 's#^spring_profiles: .*$#spring_profiles: [ mysql, ldap ]#' /var/vcap/jobs/uaa/config/uaa.yml

cat <<LDAP >> /var/vcap/jobs/uaa/config/uaa.yml
ldap:
  profile:
    file: "ldap/ldap-search-and-bind.xml"
  base:
    url: 'ldap://10.0.2.2:389/'
    mailAttributeName: 'mail'
    userDn: 'cn=admin,dc=pivotal,dc=org'
    password: 'password'
    mailAttributeName: 'mail'
    searchBase: 'ou=people,o=sevenSeas,dc=pivotal,dc=org'
    searchFilter: 'uid={0}'
LDAP
MODIFY_UAA_YML
