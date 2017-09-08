### Cloud Foundry Management Demo

A demonstration of [Cloud Foundry
Management](https://github.com/pivotalservices/cf-mgmt) for syncing your LDAP
directory to Cloud Foundry roles. Currently designed to run entirely on your
local machine to simplify setup and allow demonstrations when network
connections are unavailable or unreliable. I'm working toward getting adapting
it to target any [Pivotal Cloud Foundry](https://pivotal.io/platform) and LDAP
directory rather than just the local [PCFdev](https://pivotal.io/pcf-dev). You
can do that pretty readily yourself, I just want to make it easier for you.

## Prerequisites

1. [VirtualBox 5.0 or higher](https://www.virtualbox.org/wiki/Downloads), which is required to run [PCFdev](https://pivotal.io/pcf-dev).
1. An LDAP server. I use [Docker for Mac](https://www.docker.com/docker-mac) and the [Docker image](https://hub.docker.com/r/cwashburn/ldap/) that [Caleb Washburn](https://github.com/calebwashburn) created for testing `cf-mgmt`.
1. [Concourse](https://concourse.ci) to run the pipelines that CF Management creates. I've developed and tested this with [Concourse Lite](https://github.com/concourse/concourse-lite), but the Concourse team has deprecated that in favor of [conourse-deployment](https://github.com/concourse/concourse-deployment). The changes should be transparent.
1. The [OpenLDAP](https://www.openldap.org/) utilities. You've already got them installed if you're on a Mac, and if you're not then your package manager can take care of it for you (see [this tutorial](https://www.digitalocean.com/community/tutorials/how-to-manage-and-use-ldap-servers-with-openldap-utilities) from Digital Ocean on how to use them, it has an install step).
1. [`direnv`](https://direnv.net/). Not strictly necessary, but the instructions assume it's there and it really improves your experience with the demo.
1. Your own fork of this repository. Concourse will load configuration files from the repository, and the demo commits changes to it to support that. I'm sure you're very nice, but I'm not going to let you commit to my repo.

## Running the demo

1. Check out your fork of this repository and change into that directory.
1. Make sure that PCF, your LDAP Server, and Concourse are running. In my setup I do this with
```bash
$ cf dev start
...
$ docker pull cwashburn/ldap
...
$ docker run -d -p 389:389 --name ldap -t cwashburn/ldap
...
```
2. *If you are running PCF Dev:* Update the `uaa.yml` fle on your PCFDev instance to connect your PCFDev instance to your LDAP server. You'll only need to do this when you create a new PCFDev instance. If you're using an instance you've already modified, the change will persist. If you're using another PCF instance, you'll need to make sure that the LDAP server is configured in Operations Manager. Restart PCF dev after your make the change.
```bash
$ cf dev ssh
...
vcap@agent-id-pcfdev-0:~$ sudo sed -i -e 's#^spring_profiles: .*$#spring_profiles: [ mysql, ldap ]#' /var/vcap/jobs/uaa/config/uaa.yml
vcap@agent-id-pcfdev-0:~$ cat <<LDAP | sudo tee -a  /var/vcap/jobs/uaa/config/uaa.yml
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
...
vcap@agent-id-pcfdev-0:~$ sudo /var/vcap/bosh/bin/monit restart uaa
```
3. Take a look at the `.envrc` file. If you are using PCFDev, the OpenLDAP docker container, and a local Concourse you shouldn't need to change it. If you're using other options, you'll need to edit it. If you're not sure what/how to edit, give it a go locally instead. Since you have your own fork, why not commit the changes?
4. Load the demo data into your LDAP server with the `data` command. Through the magic of [`direnv`](https://direnv.net/), it's in your path if you're in the working directory from your checkout.
5. Initialize the demo with the `init` command. This will prepare your repository for use with the `cf-mgmt` pipelines and initailize `cf-mgmt`. The script creates a branch for the demo and enables the pipelines and your CF management config to be committed.
6. Configure CF Management for the demo with the `config` command. This will generate the config files needed to sync the directory with PCF, and commit them to the demo branch.
7. Generate pipelines that automate CF Management synchronization with the `pipeline` command. This will customize the pipelines for your demo, upload them to your Concourse environment, and unpause them so they'll beging to run.
8. Watch the pipelines run. If you're running locally, you can [click here](http://192.168.100.4:8080) to see them.
9. Login to PCF and use `cf orgs` and `cf spaces` to inspect what was created. You can also use `cf org-users` and `cf space-users` to see how roles were assigned.
```bash
$ cf login -a https://api.local.pcfdev.io --skip-ssl-validation
...
$ cf orgs
...
$ cf spaces
...
```
10. Edit `orgs.yml` and commit/push your changes. Watch the pipeline execute and re-inspect your orgs and spaces.
11. When you're done with the demo, you can clean up after yourself with the `cleanup`. It will put your fork back to it's original state without the `demo` branch.
