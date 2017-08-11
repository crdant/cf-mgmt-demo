0. Have at the ready an installation of PCF ([PCFdev](https://pivotal.io/pcf-dev) will do), an LDAP server (try the Docker image `cwashburn/ldap` for an easy local version), and an installation of [Concourse](https://concourse.ci).
1. Edit `.envrc`. If you are using Concourse Lite and PCFdev you'll only need to change the LDAP values.
2. Load the file `data/apache-ds-tutorial.ldif` into your LDAP server
2. Run `init.sh`.
3. Run `config.sh`.
4. Run `pipeline.sh`.
5. Watch the pipeline run.
6. Run `cf orgs` and `cf spaces` to inspect what was created.
7. Edit `orgs.yml` and commit/push your changes. Watch the pipeline execute and re-inspect your orgs and spaces.
