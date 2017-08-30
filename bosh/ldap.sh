#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"

stemcell_version=3431.13
stemcell_checksum=8ae6d01f01f627e70e50f18177927652a99a4585

ldap_version=0.3.0
ldap_checksum=36fd3294f756372ff9fbbd6dfac11fe6030d02f9
ldap_static_ip=10.0.31.
# ldap_static_ip=10.244.0.2
ldap_port=636

ssl_certificates () {
  echo "Creating SSL certificate..."

  common_name="ldap.${subdomain}"
  country="US"
  state="MA"
  city="Cambridge"
  organization="${domain}"
  org_unit="LDAP"
  email="${account}"
  alt_names="IP:${ldap_static_ip},DNS:localhost,IP:127.0.0.1"
  subject="/C=${country}/ST=${state}/L=${city}/O=${organization}/OU=${org_unit}/CN=${common_name}/emailAddress=${email}"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${ldap_key_file}" -out "${ldap_cert_file}" -subj "${subject}" -reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=${alt_names}\n"))  > /dev/null
}

stemcell () {
  bosh -n -e ${env_id} upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${stemcell_version} --sha1 ${stemcell_checksum}
}

releases () {
  bosh -n -e ${env_id} upload-release https://github.com/cloudfoundry-community/openldap-boshrelease/archive/v${ldap_version}.tar.gz --sha1 ${ldap_checksum}
}


safe_auth () {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
}

deploy () {
  local manifest=${manifest_dir}/ldap.yml
  safe_auth
  safe set secret/bootstrap/ldap/admin value=`generate_passphrase 4`

  ldap_olc_suffix='cn=config'
  ldap_olc_root_dn="cn=admin,dc=crdant,dc="
  ldap_olc_root_password=`safe get secret/bootstrap/concourse/admin:value`

  bosh -n -e ${env_id} -d ldap deploy ${manifest} \
    --var olc-suffix="${ldap_olc_suffix}" --var olc-root-dn="${ldap_olc_root_dn}" --var olc-root-password="$ldap_olc_root_password" \
    --var-file ldap-cert="${key_dir}/ldap-${env_id}.crt" --var-file ldap-key="${key_dir}/ldap-${env_id}.key"
}

firewall() {
  gcloud --project "${project}" compute firewall-rules create "${env_id}-ldap" --allow="tcp:${ldap_port}" --source-tags="${env_id}-bosh-open" --target-tags="${env_id}-internal" --network="${env_id}-network "
}

tunnel () {
  ssh -fnNT -L ${ldap_port}:${ldap_static_ip}:${ldap_port} jumpbox@${jumpbox} -i $BOSH_GW_PRIVATE_KEY
}

teardown () {
  bosh -n -e ${env_id} -d ldap delete-deployment
  gcloud --project "${project}" compute firewall-rules delete "${env_id}-ldap"
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      certificates )
        ssl_certificates
        ;;
      security )
        ssl_certificates
        ;;
      stemcell )
        stemcell
        ;;
      release )
        release
        ;;
      deploy )
        deploy
        ;;
      firewall )
        firewall
        ;;
      tunnel )
        tunnel
        ;;
      teardown )
        teardown
        ;;
      * )
        echo "Unrecognized option: $1" 1>&2
        exit 1
        ;;
    esac
    shift
  done
  exit
fi

ssl_certificates
stemcell
releases
deploy
firewall
tunnel
init
