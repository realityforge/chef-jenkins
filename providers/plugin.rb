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

def update_plugin?(upgrade)
  data = jenkins_json_request("pluginManager/api/json?tree=plugins[shortName,hasUpdate,version]")
  return true unless data
  data.to_hash["plugins"].each do |plugin|
    if plugin["shortName"] == new_resource.name
      Chef::Log.debug("Jenkins_plugin: #{plugin["shortName"]}:#{plugin["version"]} - Found existing (Wanted version=#{new_resource.version} hasUpdate=#{plugin["hasUpdate"]})")
      return false if plugin["version"].to_s == new_resource.version.to_s
      return true unless new_resource.version.nil?
      return (plugin["hasUpdate"].to_s == 'true' && upgrade)
    end
  end
  true
end

def plugin_url
  new_resource.url.nil? ? new_resource.name : new_resource.url
end

notifying_action :install do

  jenkins_cli "install-plugin #{plugin_url}" do
    only_if { update_plugin?(false) }
  end
end

notifying_action :update do
  jenkins_cli "install-plugin #{plugin_url}" do
    only_if { update_plugin?(true) }
  end
end
