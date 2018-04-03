require File.expand_path("~/src/bugmark/config/environment")

class Bmxsim_Issue
  def initialize(id, repo_uuid, difficulty=1)
    @status = 'open'  # closed or open
    @complete = 0  # percentage of completion
    @difficulty = difficulty  # difficulty level of issue
    @id = id  # id of this issue
    @bmx_issue = FB.create(:issue, stm_repo_uuid: repo_uuid, exid: id, stm_status: "open").issue
    @uuid = @bmx_issue.uuid
    puts "New issue (#{@id}) with uuid: #{@uuid}"
  end
  def uuid
    @uuid
  end
  def close
    @status = 'closed'
    IssueCmd::Sync.new({exid: @id, stm_status: "closed"}).project
  end
  def reopen
    @status = 'open'
    IssueCmd::Sync.new({exid: @id, stm_status: "open"}).project
  end
  def get_status
    @status
  end
  def get_id
    @id
  end
end

class Bmxsim_IssueTracker
  def initialize(bmx_repo)
    @issues = []
    @bmx_repo = bmx_repo
    @uuid = @bmx_repo.uuid
    puts "New Issue tracker, with uuid: #{@uuid}"
  end
  def uuid
    @uuid
  end
  def open_issue
    puts "new issue, #{(@issues.count+1)}, #{@uuid}"
    iss = Bmxsim_Issue.new((@issues.count+1), @uuid)
    @issues.push(iss)
    return @issues.last
  end
  def get_issue(id)
    @issues[id-1]
  end
  def close_issue(id)
    get_issue(id).close
  end
  def list_issues
    @issues
  end
  def list_open_issues
    result = @issues.select do |i|
      i.get_status == 'open'
    end
    return result
  end
  def list_closed_issues
    result = @issues.select do |i|
      i.get_status == 'closed'
    end
    return result
  end
end
