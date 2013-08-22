require "spec_helper"

describe Account do
  it {should have_many :caller_groups}

  it "returns the activated status as the paid flag" do
    create(:account, :activated => true).paid?.should be_true
    create(:account, :activated => false).paid?.should be_false
  end

  it "can toggle the call_recording setting" do
    account = create(:account, :record_calls => true)
    account.record_calls?.should be_true
    account.toggle_call_recording!
    account.record_calls?.should be_false
    account.toggle_call_recording!
    account.record_calls?.should be_true
  end

  it "lists all custom fields" do
    account = create(:account)
    field1 = create(:custom_voter_field, :name => "field1", :account => account)
    field2 = create(:custom_voter_field, :name => "field2", :account => account)
    field3 = create(:custom_voter_field, :name => "field3", :account => account)
    account.custom_fields.should == [field1, field2, field3]
  end

  

end
