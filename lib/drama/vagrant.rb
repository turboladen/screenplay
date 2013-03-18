require 'vagrant'
require_relative 'screenplay'


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
      screenplay = Drama::Screenplay.write(config.stage) do
        screenplay_text = File.read 'Dramafile'
        b = get_binding
        b.eval(screenplay_text)
      end

      actors = screenplay.actors.find_all do |actor|
        actor.config[:host] == screenplay.stages[config.stage]
      end
      p actors

      actors.each do |actor|
        actor.set ssh_key_path: env[:vm].env.default_private_key_path
      end

      screenplay.action!
    end
  end
end

Vagrant.provisioners.register(:drama, Drama::Provisioner)
