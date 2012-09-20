#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

user node['jenkins']['server']['user'] do
  home node['jenkins']['server']['home']
end

directory node['jenkins']['server']['home'] do
  recursive true
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['group']
end

directory "#{node['jenkins']['server']['home']}/.ssh" do
  mode 0700
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['group']
end

pkey = "#{node['jenkins']['server']['home']}/.ssh/id_rsa"
execute "ssh-keygen -f #{pkey} -N ''" do
  user  node['jenkins']['server']['user']
  group node['jenkins']['server']['group']
  not_if { File.exists?(pkey) }
end

ruby_block "store jenkins ssh pubkey" do
  block do
    node.set['jenkins']['server']['pubkey'] = File.open("#{pkey}.pub") { |f| f.gets }
  end
end

case node.platform
when "ubuntu", "debian"
  include_recipe "apt"
  include_recipe "java"

  pid_file = "/var/run/jenkins/jenkins.pid"
  install_starts_service = true

  apt_repository "jenkins" do
    uri "#{node.jenkins.package_url}/debian"
    components %w[binary/]
    key "http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key"
    action :add
  end
when "centos", "redhat"
  include_recipe "yum"

  pid_file = "/var/run/jenkins.pid"
  install_starts_service = false

  yum_key "jenkins" do
    url "#{node.jenkins.package_url}/redhat/jenkins-ci.org.key"
    action :add
  end

  yum_repository "jenkins" do
    description "repository for jenkins"
    url "#{node.jenkins.package_url}/redhat/"
    key "jenkins"
    action :add
  end
end

service "jenkins" do
  supports [ :stop, :start, :restart, :status ]
  status_command "test -f #{pid_file} && kill -0 `cat #{pid_file}`"
  action :nothing
end

log "jenkins: install and start" do
  notifies :install, "package[jenkins]", :immediately
  notifies :start, "service[jenkins]", :immediately unless install_starts_service
  not_if do
    File.exists? "/usr/share/jenkins/jenkins.war"
  end
end

template "/etc/default/jenkins"

package "jenkins" do
  action :nothing
  notifies :create, "template[/etc/default/jenkins]", :immediately
end

jenkins_ensure_enabled "initial_startup"

