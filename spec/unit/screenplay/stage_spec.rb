require 'screenplay/stage'


describe Screenplay::Stage do
  subject do
    class Tester
      include Screenplay::Stage
    end

    Tester.new
  end

  describe '.included' do
    it 'adds the base includer class to the internal list of stages' do
      Screenplay::Environment.stages.should_receive(:<<).with('tester')

      subject
    end
  end

  describe '#action' do
    let(:host_group) do
      {
        first: double('Host'),
        second: double('Host')
      }
    end

    before do
      subject.instance_variable_set(:@host_group, host_group)
    end

    it 'calls action on each host in @host_group' do
      host_group.each do |_, host|
        host.should_receive(:action!)
      end

      subject.action!
    end
  end
end
