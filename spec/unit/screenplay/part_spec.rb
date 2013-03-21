require 'screenplay/part'


describe Screenplay::Part do
  let(:host) { 'testhost' }
  let(:options) { { one: 'one', two: 'two' } }

  describe '.play' do
    it 'creates a new Part with the params that it got' do
      Screenplay::Part.should_receive(:new).with(host, options)
      Screenplay::Part.play(host, options)
    end
  end

  describe '#initialize' do
    its(:host) { eq(host) }

    context 'no options/params passed in' do
      it 'calls #play with no args' do
        Screenplay::Part.any_instance.should_receive(:play) do |*args|
          args.size.should be_zero
        end

        Screenplay::Part.new(host)
      end
    end

    context 'options/params passed in' do
      it 'calls #play with those options' do
        Screenplay::Part.any_instance.should_receive(:play).with(options)

        Screenplay::Part.new(host, options)
      end
    end
  end
end
