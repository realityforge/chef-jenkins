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

use_inline_resources

action :create do
  jenkins_reload "config_reload" do
    action(:nothing)
  end

  new_resource.configs.each_pair do |config_file, config|
    template "#{node['jenkins']['server_dir']}/#{config_file}.xml" do
      source config['source'] || "#{config_file}.xml.erb"
      cookbook config['cookbook']
      mode '0600'
      owner node['jenkins']['user']
      group node['jenkins']['group']
      variables config
      notifies :run, 'jenkins_reload[config_reload]', :delayed
    end
  end
end
