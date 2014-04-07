#
# Copyright Peter Donald
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

class Chef
  class Jenkins
    class << self
      def jenkins_server_url(node)
        "http://#{node['jenkins']['server']['host']}:#{node['jenkins']['server']['port']}"
      end

      def jenkins_request(node, url)
        uri = URI("#{jenkins_server_url(node)}/#{url}")
        Net::HTTP.new(uri.hostname, uri.port).start do |http|
          req = Net::HTTP::Get.new(uri.request_uri)
          req.basic_auth node['jenkins']['api_user'], node['jenkins']['api_token'] if node['jenkins']['api_user']
          return http.request(req)
        end
      end

      def jenkins_post(node, url, content)
        uri = URI("#{jenkins_server_url(node)}/#{url}")
        Net::HTTP.new(uri.hostname, uri.port).start do |http|
          req = Net::HTTP::Post.new(uri.request_uri)
          req.basic_auth node['jenkins']['api_user'], node['jenkins']['api_token'] if node['jenkins']['api_user']
          req.body = content
          return http.request(req)
        end
      end

      def jenkins_json_request(node, url)
        res = jenkins_request(node, url)
        res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body.to_s) : nil
      end
    end
  end
  module JenkinsCLI
    def jenkins_server_url
      new_resource.server_url || ::Chef::Jenkins.jenkins_server_url(node)
    end

    def jenkins_request(url)
      ::Chef::Jenkins.jenkins_request(node, url)
    end

    def jenkins_post(url, content)
      ::Chef::Jenkins.jenkins_post(node, url, content)
    end

    def jenkins_json_request(url)
      ::Chef::Jenkins.jenkins_json_request(node, url)
    end

    def jenkins_command(command)
      args = []

      args << "-s #{jenkins_server_url}"
      args << "-i #{new_resource.private_key}" if new_resource.private_key
      args << command

      "#{node['java']['java_home']}/bin/java -jar #{Chef::Config[:file_cache_path]}/jenkins-cli.jar #{args.join(' ')}"
    end
  end
end
