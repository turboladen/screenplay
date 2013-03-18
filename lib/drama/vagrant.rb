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

      actors = []
      puts "stages: #{Drama.stages}"
      puts "config stage: #{config.stage}"

      stages = Drama.stages.find_all do |stage|
        stage == config.stage || stage == config.stage.to_s
      end

      abort "No stages found that match stage '#{config.stage}'" if stages.empty?

      stages.each do |stage|
        klass = Drama.const_get(stage.capitalize)
        actors << klass.new
        actors.last.build_commands
      end

      actors.each { |actor| actor.action! }
    end
  end
end

Vagrant.provisioners.register(:drama, Drama::Provisioner)
