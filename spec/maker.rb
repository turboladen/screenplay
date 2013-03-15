require_relative 'spec_helper'
require 'drama'

describe Drama do
  specify { Drama::VERSION.should == '0.1.0' }

  describe "#initialize" do
    it "should do some stuff" do
      pending "FIXME"
    end
  end
end
