require 'screenplay'


describe Screenplay do
  specify { Screenplay::VERSION.should == '0.1.0' }

  describe '.sketch' do
    let(:hosts) do
      h1 = double 'host1'
      h2 = double 'host2'

      [h1, h2]
    end

    let(:block) { Proc.new {} }
    let(:sketch) do
      double 'Screenplay::Sketch'
    end

    it 'creates new Sketch and calls #action! on it' do
      sketch.should_receive(:action!).with(&block)
      Screenplay::Sketch.should_receive(:new).with(hosts, nil, nil).
        and_return(sketch)

      Screenplay.sketch(hosts, &block)
    end
  end

  describe '.rewind' do
    let(:files) do
      f1 = double 'File'
      f2 = double 'File'

      [f1, f2]
    end

    let(:change) { double 'Screenplay::HostChanges' }

    it 'loads each YAML file and calls #rewind on it' do
      change.should_receive(:rewind).twice

      files.each do |f|
        YAML.should_receive(:load_file).with(f).and_return change
      end

      Screenplay.rewind(files)
    end
  end
end
