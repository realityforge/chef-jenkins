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

include_recipe "java"

group node['jenkins']['group'] do
end

user node['jenkins']['user'] do
  comment 'Jenkins Continuous Integration Server'
  gid node['jenkins']['group']
  home node['jenkins']['base_dir']
  shell '/bin/bash'
end

directory node['jenkins']['base_dir'] do
  mode 0700
  owner node['jenkins']['user']
  group node['jenkins']['group']
  recursive true
end

directory "#{node['jenkins']['base_dir']}/.ssh" do
  mode 0700
  owner node['jenkins']['user']
  group node['jenkins']['group']
end

pkey = "#{node['jenkins']['base_dir']}/.ssh/id_rsa"
execute "ssh-keygen -f #{pkey} -N ''" do
  user node['jenkins']['user']
  group node['jenkins']['group']
  not_if { File.exists?(pkey) }
end

ruby_block "store jenkins ssh pubkey" do
  block do
    node.override['jenkins']['server']['pubkey'] = File.open("#{pkey}.pub") { |f| f.gets }
  end
end

directory node['jenkins']['server_dir'] do
  mode "0700"
  owner node['jenkins']['user']
  group node['jenkins']['group']
  recursive true
end

directory node['jenkins']['work_dir'] do
  mode "0700"
  owner node['jenkins']['user']
  group node['jenkins']['group']
  recursive true
end

version = node['jenkins']['version']
unless node['jenkins']['version']
  begin
    node.override['jenkins']['version'] =
      `curl  -I "#{node['jenkins']['mirror']}/war/latest/jenkins.war"`.scan(/Location:.*\/war\/(.*)\/jenkins.war/).flatten[0]
  rescue Exception
    raise "Unable to determine version of jenkins to use."
  end
end

package_url = "#{node['jenkins']['mirror']}/war/#{node['jenkins']['version']}/jenkins.war"
war_file = "#{node['jenkins']['base_dir']}/jenkins-#{node['jenkins']['version']}.war"

remote_file war_file do
  source package_url
  mode "0600"
  owner node['jenkins']['user']
  group node['jenkins']['group']
  action :create_if_missing
end

service "jenkins" do
  provider Chef::Provider::Service::Upstart
  supports :start => true, :restart => true, :stop => true
  action :nothing
end

requires_authbind = node['jenkins']['server']['port'] < 1024
if requires_authbind
  include_recipe 'authbind'

  authbind_port "AuthBind Jenkins Port #{node['jenkins']['server']['port']}" do
    port node['jenkins']['server']['port']
    user node['jenkins']['user']
  end
end

java_args = []
java_args << "-Xmx256m"
# Required for authbind
java_args << "-Djava.net.preferIPv4Stack=true" # make jenkins listen on IPv4 address

args = []
args << "--ajp13Port=-1"
args << "--httpsPort=-1"
args << "--httpPort=#{node['jenkins']['server']['port']}"
args << "--httpListenAddress=#{node['jenkins']['server']['host']}"
args << "--webroot=#{node['jenkins']['work_dir']}"
# --javahome=$JAVA_HOME
# --argumentsRealm.passwd.$ADMIN_USER=[password]
# --argumentsRealm.$ADMIN_USER=admin

template "/etc/init/jenkins.conf" do
  source "upstart.conf.erb"
  mode "0644"
  cookbook 'jenkins'
  variables(:war_file => war_file, :java_args => java_args, :args => args, :authbind => requires_authbind, :listen_ports => [node['jenkins']['server']['port']])
  notifies :restart, resources(:service => "jenkins"), :delayed
end

service "jenkins" do
  provider Chef::Provider::Service::Upstart
  supports :start => true, :restart => true, :stop => true
  action [:enable, :start]
end

jenkins_ensure_enabled "initial_startup"

if node['jenkins']['update_center_url']
  bash "update jenkins plugin cache" do
    user node['jenkins']['user']
    group node['jenkins']['group']
    code "curl  -L #{node['jenkins']['update_center_url']} | sed '1d;$d' | curl -X POST -H 'Accept: application/json' -d @- #{::Chef::Jenkins.jenkins_server_url(node)}/updateCenter/byId/default/postBack"
  end
end
