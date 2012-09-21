Description
===========

Installs and configures Jenkins CI server.  Resource providers to support automation via jenkins-cli, including job create/update.

Requirements
============

Chef
----

* Chef version 0.10.10 or higher

Platform
--------

* 'default' - Server installation - currently supports Red Hat/CentOS 5.x and Ubuntu 8.x/9.x/10.x

Java
----

Jenkins requires Java 1.5 or higher, which can be installed via the Opscode java cookbook or windows::java recipe.

Jenkins node authentication
---------------------------

If your Jenkins instance requires authentication, you'll either need to embed user:pass in the jenkins.server.url or issue a jenkins-cli.jar login command prior to using the cli LWRPs.  For example, define a role like so:

  name "jenkins_ssh_node"
  description "cli login & register ssh slave with Jenkins"
  run_list %w(vmw::jenkins_login vmw::perform_admin)

Where the jenkins_login recipe is simply:

  jenkins_cli "login --username #{node[:jenkins][:username]} --password #{node[:jenkins][:password]}"

Attributes
==========

* jenkins[:mirror] - Base URL for downloading Jenkins (server)
* jenkins[:server][:home] - JENKINS_HOME directory
* jenkins[:server][:user] - User the Jenkins server runs as
* jenkins[:server][:group] - Jenkins user primary group
* jenkins[:server][:port] - TCP listen port for the Jenkins server
* jenkins[:server][:url] - Base URL of the Jenkins server
* jenkins[:server][:plugins] - Download the latest version of plugins in this list, bypassing update center

Usage
=====

'default' recipe
----------------

Installs a Jenkins CI server using the http://jenkins-ci.org/redhat RPM.  The recipe also generates an ssh private key and stores the ssh public key in the node 'jenkins[:pubkey]' attribute for use by the node recipes.

'jenkins_cli' resource provider
-------------------------------

This resource can be used to execute the Jenkins cli from your recipes.  For example, install plugins via update center and restart Jenkins:

    %w(git URLSCM build-publisher).each do |plugin|
      jenkins_cli "install-plugin #{plugin}"
      jenkins_cli "safe-restart"
    end

'jenkins_job' resource provider
-------------------------------

This resource manages jenkins jobs, supporting the following actions:

   :create, :update, :delete, :build, :disable, :enable

The 'create' and 'update' actions require a jenkins job config.xml.  Example:

    git_branch = 'master'
    job_name = "sigar-#{branch}-#{node[:os]}-#{node[:kernel][:machine]}"

    job_config = File.join(node[:jenkins][:server][:home], "#{job_name}-config.xml")

    jenkins_job job_name do
      action :nothing
      config job_config
    end

    template job_config do
      source "sigar-jenkins-config.xml"
      variables :job_name => job_name, :branch => git_branch
      notifies :update, resources(:jenkins_job => job_name), :immediately
      notifies :build, resources(:jenkins_job => job_name), :immediately
    end

Issues
======

* CLI authentication - http://issues.jenkins-ci.org/browse/JENKINS-3796

License & Author
================

There are many contributors to this cookbook. It was a fork of AJ Christensen's Jenkins cookbook that was ultimately
a fork a downstream fork of Doug MacEachern's Hudson cookbook (https://github.com/dougm/site-cookbooks). These are the
people that deserve all the glory.

Author:: Doug MacEachern (<dougm@vmware.com>)

Contributor:: AJ Christensen <aj@junglist.gen.nz>
Contributor:: Fletcher Nichol <fnichol@nichol.ca>
Contributor:: Roman Kamyk <rkj@go2.pl>
Contributor:: Darko Fabijan <darko@renderedtext.com>

Copyright:: 2010, VMware, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
