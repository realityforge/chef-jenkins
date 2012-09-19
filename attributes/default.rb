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
include_attribute "java::default"

default['jenkins']['mirror'] = "http://mirrors.jenkins-ci.org"
default['jenkins']['package_url'] = "http://pkg.jenkins-ci.org"

default['jenkins']['server']['home'] = "/var/lib/jenkins"
default['jenkins']['server']['user'] = "jenkins"

case node[:platform]
when "debian", "ubuntu"
  default['jenkins']['server']['group'] = 'nogroup'
else
  default['jenkins']['server']['group'] = 'jenkins'
end

default['jenkins']['server']['port'] = 8080
default['jenkins']['server']['host'] = node['fqdn']
default['jenkins']['server']['url']  = "http://#{node['jenkins']['server']['host']}:#{node['jenkins']['server']['port']}"
