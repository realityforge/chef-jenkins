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
  class JenkinsConfigXML

    def scm_config
      @scm_config
    end

    def scm_config=(scm_config)
      @scm_config = scm_config
      self
    end

    def git_scm_config(git_url, branch_spec, options)
      self.scm_config = Proc.new do |xml|
        xml.scm(:class => 'hudson.plugins.git.GitSCM') do
          xml.configVersion(2)
          xml.userRemoteConfigs do
            xml.tag!('hudson.plugins.git.UserRemoteConfig') do
              xml.name('origin')
              xml.refspec('+refs/heads/*:refs/remotes/origin/*')
              xml.url(git_url)
            end
          end
          xml.branches do
            xml.tag!('hudson.plugins.git.BranchSpec') do
              xml.name(branch_spec)
            end
          end
          xml.disableSubmodules(false)
          xml.recursiveSubmodules(false)
          xml.doGenerateSubmoduleConfigurations(false)
          xml.authorOrCommitter(false)
          xml.clean(false)
          xml.wipeOutWorkspace(true)
          xml.pruneBranches(false)
          xml.remotePoll(false)
          xml.ignoreNotifyCommit(false)
          xml.useShallowClone(false)
          xml.buildChooser(:class => "hudson.plugins.git.util.DefaultBuildChooser")
          xml.gitTool('Default')
          if options['browser']
            if options['browser']['type'] == 'github'
              xml.browser(:class => "hudson.plugins.git.browser.GithubWeb") do
                xml.url(options['browser']['url'])
              end
            end
          end

          xml.submoduleCfg(:class => "list")
          xml.relativeTargetDir('')
          xml.reference('')
          xml.excludedRegions('')
          xml.excludedUsers('')
          xml.gitConfigName('')
          xml.gitConfigEmail('')
          xml.skipTag(true)
          xml.includedRegions('')
          xml.scmName('')
        end
      end
      self
    end

    def properties
      @properties ||= []
    end

    def add_property_section(&block)
      self.properties << block
      self
    end

    def github_project_property(project_url)
      add_property_section do |xml|
        xml.tag!('com.coravy.hudson.plugins.github.GithubProjectProperty') do
          xml.projectUrl(project_url)
        end
      end
    end

    def parameters_definition_property(parameters)
      add_property_section do |xml|
        xml.tag!('hudson.model.ParametersDefinitionProperty') do
          xml.parameterDefinitions do
            parameters.each_pair do |key, value|
              description = value['description'] || ''
              if value['choices']
                xml.tag!('hudson.model.ChoiceParameterDefinition') do
                  xml.name(key.to_s)
                  xml.description(description)
                  xml.choices(:class => "java.util.Arrays$ArrayList") do
                    xml.a(:class => "string-array") do
                      value['choices'].each do |choice|
                        xml.string(choice)
                      end
                    end
                  end
                end
              else
                xml.tag!('hudson.model.StringParameterDefinition') do
                  xml.name(key.to_s)
                  xml.description(description)
                  xml.defaultValue(value['defaultValue'] || '')
                end
              end
            end
          end
        end
      end
    end

    def builders
      @builders ||= []
    end

    def add_builder_section(&block)
      self.builders << block
      self
    end

    def shell_builder(command)
      add_builder_section do |xml|
        xml.tag!('hudson.tasks.Shell') do
          xml.command(command)
        end
      end
    end

    def triggers
      @triggers ||= []
    end

    def add_trigger_section(&block)
      self.triggers << block
      self
    end

    def scm_trigger(spec)
      add_trigger_section do |xml|
        xml.tag!('hudson.triggers.SCMTrigger') do
          xml.spec(spec)
        end
      end
    end

    def timer_trigger(spec)
      add_trigger_section do |xml|
        xml.tag!('hudson.triggers.TimerTrigger') do
          xml.spec(spec)
        end
      end
    end

    def publishers
      @publishers ||= []
    end

    def add_publisher_section(&block)
      self.publishers << block
      self
    end

    def artifact_publisher(artifacts_pattern, options = {})
      add_publisher_section do |xml|
        xml.tag!('hudson.tasks.ArtifactArchiver') do
          xml.artifacts(artifacts_pattern)
          latest_only = options[:latest_only].nil? ? false : !!options[:latest_only]
          xml.latestOnly(latest_only)
        end
      end
    end

    EMAIL_TRIGGER_CLASSES = {
      :unstable => 'hudson.plugins.emailext.plugins.trigger.UnstableTrigger',
      :failure => 'hudson.plugins.emailext.plugins.trigger.FailureTrigger',
      :still_failing => 'hudson.plugins.emailext.plugins.trigger.StillFailingTrigger',
      :fixed_trigger => 'hudson.plugins.emailext.plugins.trigger.FixedTrigger',
      :still_unstable => 'hudson.plugins.emailext.plugins.trigger.StillUnstableTrigger',
    }

    def extended_email_publisher(recipient_list, triggers = {:all => []})
      add_publisher_section do |xml|
        xml.tag!('hudson.plugins.emailext.ExtendedEmailPublisher') do
          xml.recipientList(recipient_list)
          xml.configuredTriggers do
            EMAIL_TRIGGER_CLASSES.keys.each do |trigger_key|
              if triggers[:all] || triggers[trigger_key]
                xml.tag!(EMAIL_TRIGGER_CLASSES[trigger_key]) do
                  xml.email do
                    xml.recipientList('')
                    xml.subject('${PROJECT_DEFAULT_SUBJECT}')
                    xml.body('${PROJECT_DEFAULT_CONTENT}')
                    xml.sendToDevelopers(false)
                    xml.sendToRequester(false)
                    xml.includeCulprits(false)
                    xml.sendToRecipientList(true)
                  end
                end
              end
            end
            xml.contentType('default')
            xml.defaultSubject('${DEFAULT_SUBJECT}')
            xml.defaultContent('${DEFAULT_CONTENT}')
            xml.attachmentsPattern('')
            xml.presendScript('')
          end
        end
      end
    end

    def downstream_build_trigger(projects, options = {})
      add_publisher_section do |xml|
        xml.tag!('hudson.tasks.BuildTrigger') do
          xml.childProjects(projects.join(','))
          xml.threshold do
            xml.name(options['condition'] || 'SUCCESS')
            xml.ordinal(0)
            xml.color('BLUE')
          end
        end
      end
    end

    def downstream_parameterized_build_trigger(projects, options = {})
      add_publisher_section do |xml|
        xml.tag!('hudson.plugins.parameterizedtrigger.BuildTrigger') do
          xml.configs do
            xml.tag!('hudson.plugins.parameterizedtrigger.BuildTriggerConfig') do
              parameters = options['parameters'] || {}
              unless parameters.empty?
                xml.configs do
                  if parameters['propertiesFile']
                    files = parameters['propertiesFile']
                    files = files.is_a?(Array) ? files : [files]
                    files.each do |f|
                      xml.tag!('hudson.plugins.parameterizedtrigger.FileBuildParameters') do
                        xml.propertiesFile(f)
                      end
                    end
                  end
                  if parameters['inline']
                    inline = parameters['inline']
                    inline = inline.is_a?(Array) ? inline : [inline]
                    inline.each do |v|
                      xml.tag!('hudson.plugins.parameterizedtrigger.PredefinedBuildParameters') do
                        xml.properties(v)
                      end
                    end
                  end
                end
              end
              xml.projects(projects.join(','))
              xml.condition(options['condition'] || 'SUCCESS')
              xml.triggerWithNoParameters(!parameters.empty?)
            end
          end
        end
      end
    end

    def jdepend_publisher(report_file)
      add_publisher_section do |xml|
        xml.tag!('hudson.plugins.jdepend.JDependRecorder') do
          xml.configuredJDependFile(report_file)
        end
      end
    end

    def javancss_publisher(report_file_pattern)
      add_publisher_section do |xml|
        xml.tag!('hudson.plugins.javancss.JavaNCSSPublisher') do
          xml.reportFilenamePattern(report_file_pattern)
          xml.targets do
            xml.tag!('hudson.plugins.javancss.JavaNCSSHealthTarget') do
              xml.metric("JAVADOC_RATIO", :class => "hudson.plugins.javancss.JavaNCSSHealthMetrics")
              xml.healthy(0.0)
              xml.unhealthy(99.0)
            end
            xml.tag!('hudson.plugins.javancss.JavaNCSSHealthTarget') do
              xml.metric("COMMENT_RATIO", :class => "hudson.plugins.javancss.JavaNCSSHealthMetrics")
              xml.healthy(0.0)
              xml.unhealthy(99.0)
            end
          end
        end
      end
    end

    def checkstyle_publisher(report_file_pattern, options = {})
      add_publisher_section do |xml|
        xml.tag!('hudson.plugins.checkstyle.CheckStylePublisher') do
          xml.healthy(options['healthy'].to_s)
          xml.unHealthy(options['unHealthy'].to_s)

          xml.pluginName('[CHECKSTYLE] ')
          xml.thresholdLimit(options['thresholdLimit'] || 'low')
          xml.defaultEncoding(options['defaultEncoding'].to_s)
          xml.canRunOnFailed(false)
          xml.useDeltaValues(false)
          xml.thresholds do
            xml.unstableTotalAll(options['unstableTotalAll'].to_s)
            xml.unstableTotalHigh(options['unstableTotalHigh'].to_s)
            xml.unstableTotalNormal(options['unstableTotalNormal'].to_s)
            xml.unstableTotalLow(options['unstableTotalLow'].to_s)
            xml.unstableNewAll(options['unstableNewAll'].to_s)
            xml.unstableNewHigh(options['unstableNewHigh'].to_s)
            xml.unstableNewNormal(options['unstableNewNormal'].to_s)
            xml.unstableNewLow(options['unstableNewLow'].to_s)
            xml.failedTotalAll(options['failedTotalAll'].to_s)
            xml.failedTotalHigh(options['failedTotalHigh'].to_s)
            xml.failedTotalNormal(options['failedTotalNormal'].to_s)
            xml.failedTotalLow(options['failedTotalLow'].to_s)
            xml.failedNewAll(options['failedNewAll'].to_s)
            xml.failedNewHigh(options['failedNewHigh'].to_s)
            xml.failedNewNormal(options['failedNewNormal'].to_s)
            xml.failedNewLow(options['failedNewLow'].to_s)
          end
          xml.shouldDetectModules(false)
          xml.dontComputeNew(false)
          xml.pattern(report_file_pattern)
        end
      end
    end

    def findbugs_publisher(report_file_pattern, options = {})
      add_publisher_section do |xml|
        xml.tag!('hudson.plugins.findbugs.FindBugsPublisher') do
          xml.healthy(options['healthy'].to_s)
          xml.unHealthy(options['unHealthy'].to_s)

          xml.pluginName('[FINDBUGS] ')
          xml.thresholdLimit(options['thresholdLimit'] || 'low')
          xml.defaultEncoding(options['defaultEncoding'].to_s)
          xml.canRunOnFailed(false)
          xml.useDeltaValues(false)
          xml.thresholds do
            xml.unstableTotalAll(options['unstableTotalAll'].to_s)
            xml.unstableTotalHigh(options['unstableTotalHigh'].to_s)
            xml.unstableTotalNormal(options['unstableTotalNormal'].to_s)
            xml.unstableTotalLow(options['unstableTotalLow'].to_s)
            xml.unstableNewAll(options['unstableNewAll'].to_s)
            xml.unstableNewHigh(options['unstableNewHigh'].to_s)
            xml.unstableNewNormal(options['unstableNewNormal'].to_s)
            xml.unstableNewLow(options['unstableNewLow'].to_s)
            xml.failedTotalAll(options['failedTotalAll'].to_s)
            xml.failedTotalHigh(options['failedTotalHigh'].to_s)
            xml.failedTotalNormal(options['failedTotalNormal'].to_s)
            xml.failedTotalLow(options['failedTotalLow'].to_s)
            xml.failedNewAll(options['failedNewAll'].to_s)
            xml.failedNewHigh(options['failedNewHigh'].to_s)
            xml.failedNewNormal(options['failedNewNormal'].to_s)
            xml.failedNewLow(options['failedNewLow'].to_s)
          end
          xml.shouldDetectModules(false)
          xml.dontComputeNew(false)
          xml.pattern(report_file_pattern)
          xml.isRankActivated(true)
        end
      end
    end

    def pmd_publisher(report_file_pattern, options = {})
      add_publisher_section do |xml|
        xml.tag!('hudson.plugins.pmd.PmdPublisher') do
          xml.healthy(options['healthy'].to_s)
          xml.unHealthy(options['unHealthy'].to_s)

          xml.pluginName('[PMD] ')
          xml.thresholdLimit(options['thresholdLimit'] || 'low')
          xml.defaultEncoding(options['defaultEncoding'].to_s)
          xml.canRunOnFailed(false)
          xml.useDeltaValues(false)
          xml.thresholds do
            xml.unstableTotalAll(options['unstableTotalAll'].to_s)
            xml.unstableTotalHigh(options['unstableTotalHigh'].to_s)
            xml.unstableTotalNormal(options['unstableTotalNormal'].to_s)
            xml.unstableTotalLow(options['unstableTotalLow'].to_s)
            xml.unstableNewAll(options['unstableNewAll'].to_s)
            xml.unstableNewHigh(options['unstableNewHigh'].to_s)
            xml.unstableNewNormal(options['unstableNewNormal'].to_s)
            xml.unstableNewLow(options['unstableNewLow'].to_s)
            xml.failedTotalAll(options['failedTotalAll'].to_s)
            xml.failedTotalHigh(options['failedTotalHigh'].to_s)
            xml.failedTotalNormal(options['failedTotalNormal'].to_s)
            xml.failedTotalLow(options['failedTotalLow'].to_s)
            xml.failedNewAll(options['failedNewAll'].to_s)
            xml.failedNewHigh(options['failedNewHigh'].to_s)
            xml.failedNewNormal(options['failedNewNormal'].to_s)
            xml.failedNewLow(options['failedNewLow'].to_s)
          end
          xml.shouldDetectModules(false)
          xml.dontComputeNew(false)
          xml.pattern(report_file_pattern)
        end
      end
    end

    def dry_publisher(report_file_pattern, options = {})
      add_publisher_section do |xml|
        xml.tag!('hudson.plugins.dry.DryPublisher') do
          xml.healthy(options['healthy'].to_s)
          xml.unHealthy(options['unHealthy'].to_s)

          xml.pluginName('[DRY] ')
          xml.thresholdLimit(options['thresholdLimit'] || 'normal')
          xml.defaultEncoding(options['defaultEncoding'].to_s)
          xml.canRunOnFailed(false)
          xml.useDeltaValues(false)
          xml.thresholds do
            xml.unstableTotalAll(options['unstableTotalAll'].to_s)
            xml.unstableTotalHigh(options['unstableTotalHigh'].to_s)
            xml.unstableTotalNormal(options['unstableTotalNormal'].to_s)
            xml.unstableTotalLow(options['unstableTotalLow'].to_s)
            xml.unstableNewAll(options['unstableNewAll'].to_s)
            xml.unstableNewHigh(options['unstableNewHigh'].to_s)
            xml.unstableNewNormal(options['unstableNewNormal'].to_s)
            xml.unstableNewLow(options['unstableNewLow'].to_s)
            xml.failedTotalAll(options['failedTotalAll'].to_s)
            xml.failedTotalHigh(options['failedTotalHigh'].to_s)
            xml.failedTotalNormal(options['failedTotalNormal'].to_s)
            xml.failedTotalLow(options['failedTotalLow'].to_s)
            xml.failedNewAll(options['failedNewAll'].to_s)
            xml.failedNewHigh(options['failedNewHigh'].to_s)
            xml.failedNewNormal(options['failedNewNormal'].to_s)
            xml.failedNewLow(options['failedNewLow'].to_s)
          end
          xml.shouldDetectModules(false)
          xml.dontComputeNew(false)
          xml.pattern(report_file_pattern)
          xml.highThreshold(options['highThreshold'].to_s)
          xml.normalThreshold(options['normalThreshold'].to_s)
        end
      end
    end

=begin
      <thresholds>
        <unstableTotalHigh>20</unstableTotalHigh>
        <unstableTotalNormal>28</unstableTotalNormal>
        <unstableNewHigh>10</unstableNewHigh>
        <unstableNewNormal>14</unstableNewNormal>
        <failedTotalHigh>24</failedTotalHigh>
        <failedTotalNormal>32</failedTotalNormal>
        <failedNewHigh>12</failedNewHigh>
        <failedNewNormal>16</failedNewNormal>
      </thresholds>
      <pattern>reports/pmd/cpd.xml</pattern>
      <highThreshold>50</highThreshold>
      <normalThreshold>25</normalThreshold>

=end

    def to_s
      base_document
    end

    private

    def base_document
      require 'builder'

      target = StringIO.new
      xml = ::Builder::XmlMarkup.new(:target => target, :indent => 2)
      xml.project do
        xml.actions
        xml.description('')
        xml.logRotator do
          xml.daysToKeep(-1)
          xml.numToKeep(15)
          xml.artifactDaysToKeep(-1)
          xml.artifactNumToKeep(-1)
        end
        self.scm_config.call(xml)
        xml.keepDependencies(false)
        xml.properties do
          self.properties.each do |property_section|
            property_section.call(xml)
          end
        end
        xml.canRoam(true)
        xml.disabled(false)
        xml.blockBuildWhenDownstreamBuilding(false)
        xml.blockBuildWhenUpstreamBuilding(false)
        xml.concurrentBuild(false)
        xml.triggers(:class => "vector") do
          self.triggers.each do |trigger_section|
            trigger_section.call(xml)
          end
        end
        xml.builders do
          self.builders.each do |builder_section|
            builder_section.call(xml)
          end
        end
        xml.publishers do
          self.publishers.each do |publisher_section|
            publisher_section.call(xml)
          end
        end
        xml.buildWrappers
      end
      target.string
    end
  end
end