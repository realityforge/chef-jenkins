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

action :run do
  ruby_block "block_until_operational" do
    block do
      count = 0
      loop do
        raise "Jenkins failed to become operational" if count > 50
        count = count + 1
        begin
          res = ::Chef::Jenkins.jenkins_request(node, '/job/test/config.xml')
          break if res.kind_of?(Net::HTTPSuccess) || res.kind_of?(Net::HTTPNotFound)
          Chef::Log.debug "service[jenkins] not responding OK to GET / #{res.inspect}"
        rescue Exception => e
          Chef::Log.debug "service[jenkins] error while accessing GET /"
        end
        sleep 1
      end
    end
    action :create
  end
end
