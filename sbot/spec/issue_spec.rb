require_relative '../issuetracker'

describe Issue do
  it "create issue" do
    iss = Issue.new(1)
    expect(iss).to_not be_nil
    expect(iss.get_status).to eq('open')
    expect(iss.get_id).to eq(1)
  end
  it "close issue" do
    iss = Issue.new(1)
    iss.close
    expect(iss.get_status).to eq('closed')
  end
  it "reopen issue" do
    iss = Issue.new(1)
    iss.close
    expect(iss.get_status).to eq('closed')
    iss.reopen
    expect(iss.get_status).to eq('open')
  end
end
