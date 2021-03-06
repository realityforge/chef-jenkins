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

default['jenkins']['version'] = nil
default['jenkins']['mirror'] = 'http://mirrors.jenkins-ci.org'
default['jenkins']['update_center_url'] = 'http://updates.jenkins-ci.org/update-center.json'

default['jenkins']['base_dir'] = '/opt/jenkins'
default['jenkins']['server_dir'] = '/opt/jenkins/server'
default['jenkins']['work_dir'] = '/opt/jenkins/work'
default['jenkins']['user'] = 'jenkins'
default['jenkins']['group'] = 'jenkins'
default['jenkins']['private_key'] = nil
default['jenkins']['api_user'] = nil
default['jenkins']['api_token'] = nil

default['jenkins']['server']['port'] = 8080
default['jenkins']['server']['host'] = node['fqdn']

default['jenkins']['server']['min_memory'] = 512
default['jenkins']['server']['max_memory'] = 512
default['jenkins']['server']['max_perm_size'] = 128
default['jenkins']['server']['max_stack_size'] = 256
