require 'spec_helper'
require 'screenplay/host'


describe Screenplay::Host do
  let(:hostname) { 'example.com' }

  let(:host) do
    h = double 'Rosh::Host'
    pkgs = double 'Rosh::Host::PackageManager'
    pkgs.should_receive(:add_observer)

    h.should_receive(:packages).and_return pkgs
    h.stub(:hostname).and_return hostname

    h
  end

  subject { Screenplay::Host.new(host) }

  describe '#initialize' do
    its(:host_changes) { should be_a Screenplay::HostChanges }
  end

  delegates = %i[hostname user shell operating_system kernel_version
    architecture distribution distribution_version remote_shell services
    packages]

  delegates.each do |delegate|
    describe "#{delegate}" do
      it 'delegates to the Rosh::Host' do
        host.should_receive(delegate)
        subject.send(delegate)
      end
    end
  end

  describe '#play_part' do
    it 'calls the .play method on the given class' do
      klass = Class.new
      klass.define_method(:play) do |**options|

      end

      klass.should_receive(:play).with(subject, one: 1, two: 2)
      subject.play_part(klass, one: 1, two: 2)
    end
  end
end
