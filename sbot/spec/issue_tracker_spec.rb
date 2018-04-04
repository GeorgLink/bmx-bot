require_relative '../issuetracker'

describe IssueTracker do
  it "initialize IssueTracker" do
    tracker = IssueTracker.new
    expect(tracker).to_not be_nil
    expect(tracker.list_issues).to be_empty
  end
  it "open issue" do
    tracker = IssueTracker.new
    tracker.open_issue
    expect(tracker.list_issues.length).to eq(1)
    expect(tracker.get_issue(1).get_id).to eq(1)
  end
  it "close issue" do
    tracker = IssueTracker.new
    tracker.open_issue
    expect(tracker.get_issue(1).get_status).to eq('open')
    tracker.close_issue(1)
    expect(tracker.get_issue(1).get_status).to eq('closed')
  end
  it "list open issues" do
    tracker = IssueTracker.new
    tracker.open_issue
    tracker.open_issue
    tracker.open_issue
    tracker.open_issue
    tracker.close_issue(2)
    tracker.close_issue(4)
    open_iss = tracker.list_open_issues
    expect(open_iss[0].get_id).to eq(1)
    expect(open_iss[1].get_id).to eq(3)
    closed_iss = tracker.list_closed_issues
    expect(closed_iss[0].get_id).to eq(2)
    expect(closed_iss[1].get_id).to eq(4)
  end
end
