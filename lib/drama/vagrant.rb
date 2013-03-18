require 'vagrant'
require_relative '../drama'
require_relative 'stage'


class Drama
  class Provisioner < Vagrant::Provisioners::Base
    class Config < Vagrant::Config::Base
      attr_accessor :stage

      def validate(env, errors)
        unless File.exists?('Dramafile')
          errors.add(I18n.t('vagrant.provisioners.drama.no_dramafile'))
        end
      end
    end

    def self.config_class
      Config
    end

    def provision!
      load 'Dramafile'

      puts "stages: #{Drama.stages}"
      puts "config stage: #{config.stage}"

      stage_name = Drama.stages.find do |stage|
        stage == config.stage || stage == config.stage.to_s
      end

      abort "No stages found that match stage '#{config.stage}'" if stage_name.empty?

      klass = Drama.const_get(stage_name.capitalize)
      stage = klass.new
      stage.build_commands

      stage.host_group.each do |name, host|
        host.set ssh_key_path: env[:vm].env.default_private_key_path
      end

      stage.action!
    end
  end
end

Vagrant.provisioners.register(:drama, Drama::Provisioner)
