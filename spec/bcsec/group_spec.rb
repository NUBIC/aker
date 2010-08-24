require File.expand_path('../../spec_helper', __FILE__)

module Bcsec
  describe Group do
    describe "serialization" do
      before do
        g = Group.new("Foo")
        g << Group.new("Bar")
        serialized = Marshal.dump(g)
        @deserialized = Marshal.restore(serialized)
      end

      it "deserializes into an object with the right type" do
        @deserialized.class.should == Group
      end

      it "deserializes into an object with the right name" do
        @deserialized.name.should == "Foo"
      end

      it "deserializes children" do
        @deserialized.should have(1).child
      end

      it "deserializes children with the right type" do
        @deserialized.children.first.class.should == Group
      end

      it "deserializes children with the right names" do
        @deserialized.children.first.name.should == "Bar"
      end
    end

    describe "#include?" do
      it "matches the exact name" do
        Group.new("Foo").include?("Foo").should be_true
      end

      it "matches case-insensitively" do
        Group.new("FOo").include?("fOo").should be_true
      end

      it "matches a symbol" do
        Group.new("Foo").include?(:foo).should be_true
      end

      it "matches another group" do
        Group.new("Bar").include?(Group.new("Bar")).should be_true
      end

      it "does not match a mismatched group" do
        Group.new("Bar").include?(Group.new("Foo")).should be_false
      end

      it "does not match a mismatched name" do
        Group.new("Bar").include?("Foo").should be_false
      end

      it "matches a child group" do
        g = Group.new("Foo").tap { |f|
          f << Group.new("Bar") << Group.new("Quux") << Group.new("Baz") }
        g.include?("quux").should be_true
      end
    end
  end
end
