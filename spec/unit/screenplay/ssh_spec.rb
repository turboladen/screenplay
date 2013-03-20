require 'screenplay/ssh'


describe Screenplay::SSH do
  let(:ssh) do
    double 'Net::SSH::Simple'
  end

  let(:hostname) { 'testhost' }
  let(:outcome) { double 'Screenplay::Outcome' }
  let(:ssh_output) { double 'SSH command output' }

  subject do
    Screenplay::SSH.new(hostname)
  end

  before do
    Net::SSH::Simple.stub(:new).and_return(ssh)
  end

  after do
    Net::SSH::Simple.unstub(:new)
  end

  describe '#initialize' do
    context 'no options passed in' do
      its(:options) { should eq(user: Etc.getlogin, timeout: 1800) }
    end

    context ':user option passed in' do
      subject { Screenplay::SSH.new('test', user: 'bobo') }
      its(:options) { should eq(user: 'bobo', timeout: 1800) }
    end

    context ':timeout option passed in' do
      subject { Screenplay::SSH.new('test', timeout: 1) }
      its(:options) { should eq(user: Etc.getlogin, timeout: 1) }
    end

    context ':meow option passed in' do
      subject { Screenplay::SSH.new('test', meow: 'cat') }
      its(:options) { should eq(user: Etc.getlogin, timeout: 1800, meow: 'cat') }
    end
  end

  describe '#set' do
    context 'no params' do
      it 'does not change @options' do
        expect { subject.set }.to_not change { subject.options }
      end
    end

    context 'one key/value pair' do
      it 'updates @options' do
        subject.set thing: 'one'
        subject.options.should include(thing: 'one')
      end
    end
  end

  describe '#unset' do
    context 'no params' do
      it 'does not change @options' do
        expect { subject.unset }.to_not change { subject.options }
      end
    end

    context 'key that exists' do
      it 'removes that option' do
        subject.options.should include(timeout: 1800)
        subject.unset :timeout
        subject.options.should_not include(timeout: 1800)
      end
    end

    context 'key that does not exist' do
      it 'does not change options' do
        expect { subject.unset :asdfasdfas }.to_not change { subject.options }
      end
    end
  end

  describe '#run' do
    context 'with no options' do
      it 'runs the command and returns an Outcome object' do
        expected_options = {
          user: Etc.getlogin,
          timeout: 1800
        }

        ssh.should_receive(:ssh).
          with(hostname, 'test command', expected_options).
          and_return ssh_output
        Screenplay::Outcome.should_receive(:new).with(ssh_output).and_return outcome

        o = subject.run 'test command'
        o.should == outcome
      end
    end

    context 'with options' do
      let(:options) do
        { one: 'one', two: 'two' }
      end

      it 'merges @options and runs the command' do
        expected_options = {
          user: Etc.getlogin,
          timeout: 1800,
          one: 'one',
          two: 'two'
        }

        ssh.should_receive(:ssh).
          with(hostname, 'test command', expected_options).and_return ssh_output
        Screenplay::Outcome.should_receive(:new).with(ssh_output).and_return outcome

        subject.run 'test command', options
      end
    end
  end

  describe '#upload' do
    context 'with no options' do
      it 'runs the command and returns an Outcome object' do
        expected_options = {
          user: Etc.getlogin,
          timeout: 1800
        }

        ssh.should_receive(:scp_ul).
          with(hostname, 'test file', '/destination', expected_options).
          and_return ssh_output
        Screenplay::Outcome.should_receive(:new).with(ssh_output).and_return outcome

        o = subject.upload 'test file', '/destination'
        o.should == outcome
      end
    end

    context 'with options' do
      let(:options) do
        { one: 'one', two: 'two' }
      end

      it 'merges @options and runs the command' do
        expected_options = {
          user: Etc.getlogin,
          timeout: 1800,
          one: 'one',
          two: 'two'
        }

        ssh.should_receive(:scp_ul).
          with(hostname, 'test file', '/destination', expected_options).
          and_return ssh_output
        Screenplay::Outcome.should_receive(:new).with(ssh_output).and_return outcome

        subject.upload 'test file', '/destination', options
      end
    end
  end
end
