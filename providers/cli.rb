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

include Chef::JenkinsCLI

use_inline_resources

action :run do
  cli_jar = "#{Chef::Config[:file_cache_path]}/jenkins-cli.jar"
  remote_file cli_jar do
    source "#{jenkins_server_url}/jnlpJars/jenkins-cli.jar"
    user node['jenkins']['user']
    group node['jenkins']['group']
    action :create_if_missing
  end

  bash "jenkins_cli #{new_resource.command}" do
    user node['jenkins']['user']
    group node['jenkins']['group']
    code jenkins_command(new_resource.command)
  end
end
