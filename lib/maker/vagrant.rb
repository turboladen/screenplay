require 'vagrant'
require_relative 'runner'


class Maker
  class Provisioner < Vagrant::Provisioners::Base
    class Config < Vagrant::Config::Base
      attr_accessor :host
      attr_accessor :plan

      def validate(env, errors)
          unless File.exists?(@plan)
            errors.add(I18n.t('vagrant.provisioners.maker.no_plans'))
          end

        if @host.nil?
          errors.add(I18n.t('vagrant.provisioners.maker.no_host'))
        end
      end

      def plan=(plan)
        @plan = File.expand_path(plan)
      end
    end

    def self.config_class
      Config
    end

    def prepare
      #
    end

    def provision!
      Maker::Runner.run do
        set host: config.host
        set ssh_key_path: env[:vm].env.default_private_key_path

        plan_text = File.read(config.plan)
        b = get_binding
        b.eval(plan_text)

        run_commands
      end
    end
  end
end

Vagrant.provisioners.register(:maker, Maker::Provisioner)
