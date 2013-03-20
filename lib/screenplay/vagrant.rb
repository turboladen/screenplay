require 'vagrant'
require_relative 'environment'
require_relative 'stage'


class Screenplay
  class Provisioner < Vagrant::Provisioners::Base
    class Config < Vagrant::Config::Base
      attr_accessor :stage

      def validate(env, errors)
        unless File.exists?('Dramafile')
          errors.add(I18n.t('vagrant.provisioners.screenplay.no_dramafile'))
        end
      end
    end

    def self.config_class
      Config
    end

    def provision!
      load 'Dramafile'

      puts "stages: #{Screenplay::Environment.stages}"
      puts "config stage: #{config.stage}"

      stage_name = Screenplay::Environment.stages.find do |stage|
        stage == config.stage || stage == config.stage.to_s
      end

      abort "No stages found that match stage '#{config.stage}'" if stage_name.empty?

      klass = Screenplay.const_get(stage_name.capitalize)
      stage = klass.new

      stage.host_group.each do |name, host|
        host.ssh.set keys: [env[:vm].env.default_private_key_path]
      end

      stage.build_commands

      stage.action!
    end

    def cleanup
      # Does something need to happen here?
    end
  end
end

Vagrant.provisioners.register(:screenplay, Screenplay::Provisioner)
