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

notifying_action :run do
  jenkins_cli "reload-configuration"

  ruby_block "block_until_operational" do
    block do
      sleep 1
      #until IO.popen("netstat -lnt").entries.select { |entry|
      #    entry.split[3] =~ /:#{node['jenkins']['server']['port']}$/
      #  }.size == 1
      #  Chef::Log.debug "service[jenkins] not listening on port #{node.jenkins.server.port}"
      #  sleep 1
      #end

      loop do
        url = URI.parse("#{::Chef::Jenkins.jenkins_server_url(node)}/job/test/config.xml")
        res = Chef::REST::RESTRequest.new(:GET, url, nil).call
        break if res.kind_of?(Net::HTTPSuccess) or res.kind_of?(Net::HTTPNotFound)
        Chef::Log.debug "service[jenkins] not responding OK to GET / #{res.inspect}"
        sleep 1
      end
    end
    action :create
  end
end
