require_relative '../person'
describe "person" do
  describe "initialize" do
    it "initialize person" do
      pps = Person.new('t','t')
      expect(pps).to_not be_nil
    end
  end
end
