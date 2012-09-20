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

def update_plugin?(plugin_name, upgrade)
  data = jenkins_json_request("pluginManager/api/json?tree=plugins[shortName,hasUpdate]")
  return false unless data
  data.to_hash["plugins"].each do |plugin|
    if plugin["shortName"] == plugin_name
      Chef::Log.debug("Jenkins_plugin: #{plugin_name} - Found existing (hasUpdate=#{plugin["hasUpdate"]})")
      return (plugin["hasUpdate"].to_s == 'true' && upgrade)
    end
  end
  true
end

notifying_action :install do
  jenkins_cli "install-plugin #{new_resource.name}" do
    only_if { update_plugin?(new_resource.name, false) }
  end
end

notifying_action :update do
  jenkins_cli "install-plugin #{new_resource.name}" do
    only_if { update_plugin?(new_resource.name, true) }
  end
end
