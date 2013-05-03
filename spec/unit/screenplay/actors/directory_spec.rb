require 'spec_helper'
require 'screenplay/actors/directory'


describe Screenplay::Actors::Directory do
  let(:dir) { double 'Rosh::Host::RemoteDir' }
  let(:observer) { double 'Some object' }

  subject do
    Screenplay::Actors::Directory.new(dir, observer)
  end

  describe '#initialize' do
    it 'adds the observer to the given Rosh directory' do
      dir.should_receive(:add_observer).with(observer)

      subject
    end
  end

  describe '#act' do
    context 'state: :absent' do
      context 'directory does not exist' do
        before { dir.stub(:exists?).and_return false }

        it 'does not try to remove the directory' do
          dir.should_not_receive(:remove)

          subject.act(:exists).should == {
            actor: :directory
          }
        end
      end

      context 'directory exists' do
        before { dir.stub(:exists?).and_return true }

        it 'removes the directory' do
          dir.should_receive(:remove)

          subject.act(:exists)
        end
      end
    end
  end
end
