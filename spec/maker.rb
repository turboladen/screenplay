require_relative 'spec_helper'
require 'maker'

describe Maker do
  specify { Maker::VERSION.should == '0.1.0' }

  describe "#initialize" do
    it "should do some stuff" do
      pending "FIXME"
    end
  end
end
