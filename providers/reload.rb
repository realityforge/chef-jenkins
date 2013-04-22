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
  jenkins_ensure_enabled "pre-reload-configuration" do
    private_key new_resource.private_key if new_resource.private_key
  end
  jenkins_cli "reload-configuration" do
    private_key new_resource.private_key if new_resource.private_key
  end
  jenkins_ensure_enabled "post-reload-configuration" do
    private_key new_resource.private_key if new_resource.private_key
  end
end
