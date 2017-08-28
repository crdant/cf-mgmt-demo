#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. ${workdir}/bbl-env.sh

env_id=`bbl env-id`
stemcell_version=3431.13
stemcell_checksum=8ae6d01f01f627e70e50f18177927652a99a4585

ldap_version=0.3.0
ldap_checksum=36fd3294f756372ff9fbbd6dfac11fe6030d02f9
ldap_static_ip=10.0.31.
ldap_port=636

export ldap_config_dn='cn=config'
export ldap_admin_user=admin
export ldap_cert_file=${key_dir}/ldap-${env_id}.crt
export ldap_key_file=${key_dir}/ldap-${env_id}.key

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

prepare_manifest () {
  local manifest=${workdir}/concourse.yml
  export atc_vault_token=`jq --raw-output '.auth.client_token' ${key_dir}/atc-${env_id}-token.json`
  export vault_cert_file=${key_dir}/vault-${env_id}.crt

  spruce merge --prune tls ${manifest_dir}/concourse.yml > $manifest
}


prepare_manifest () {
  local manifest=${workdir}/ldap.yml
  safe_auth
  safe set secret/bootstrap/ldap/admin value=`generate_passphrase 4`
  export ldap_password=`safe get secret/bootstrap/concourse/admin:value`

  ldap_static_ip=${ldap_static_ip} spruce merge ${manifest_dir}/ldap.yml > ${manifest}
}

deploy () {
  local manifest=${workdir}/ldap.yml
  bosh -n -e ${env_id} -d ldap deploy ${manifest}
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
      manifest )
          prepare_manifest
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
prepare_manifest
deploy
firewall
tunnel
init
