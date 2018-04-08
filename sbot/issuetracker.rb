#!/usr/bin/env ruby

# (c) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

require File.expand_path("~/src/bugmark/config/environment")

class Bmxsim_Issue
  def initialize(id, repo_uuid, project=1, difficulty=1)
    @status = 'open'  # closed or open
    @progress = 0  # percentage of completion
    @project = project  # in the simulation we have different projects
    @difficulty = difficulty  # difficulty level of issue
    @id = id  # id of this issue
    @bmx_issue = FB.create(:issue, stm_repo_uuid: repo_uuid, exid: id, stm_status: "open").issue
    @uuid = @bmx_issue.uuid
    @create_day = $sim_day
    @close_day = nil
  end
  def uuid
    @uuid
  end
  def close
    @status = 'closed'
    IssueCmd::Sync.new({exid: @id, stm_status: "closed"}).project
    @close_day = $sim_day
  end
  def reopen
    @status = 'open'
    IssueCmd::Sync.new({exid: @id, stm_status: "open"}).project
    @close_day = nil
  end
  def get_status
    @status
  end
  def get_progress
    @progress
  end
  def get_id
    @id
  end
  def get_age
    $sim_day - @create_day
  end
  def get_resolution_days
    @close_day - @create_day
  end
  def get_difficulty
    @difficulty
  end
  def work(effort)
    # figure out how much work is left to do
    @progress = [@progress + (100.0*effort/@difficulty).ceil,100].min
    # close issue, if work is complete
    close unless @progress < 100
  end
end

class Bmxsim_IssueTracker
  def initialize()
    @issues = []
    # @project_bmx_repo = []
    @project_bmx_repo_uuid = []
    # puts "New Issue tracker, with uuid: #{@uuid}"
  end
  def uuid
    @uuid
  end
  def add_project(proj_number)

    bmx_repo = RepoCmd::Create.new({name: 'TestRepo'+proj_number.to_s, type: 'Repo::Test'}).project.repo
    # bmx_repo = FB.create(:repo).repo
    # @project_bmx_repo.insert(proj_number, bmx_repo)
    @project_bmx_repo_uuid.insert(proj_number, bmx_repo.uuid)
    return bmx_repo.uuid
  end
  def get_project_repo_uuid(proj_number)
    @project_bmx_repo_uuid.fetch(proj_number)
  end
  def get_project_health(proj_number)
    repo_uuid = get_project_repo_uuid(proj_number)
    proj_health = {
      open_issues: nil,  # What is the number of open issues?
      closed_issues: nil,  # What is the number of closed issues?
      resolution_efficiency: nil, # What is the number of closed issues/number of abandoned issues?
      open_issue_age: nil,  # What is the the age of open issues?
      closed_issue_resolution_duration: nil  # What is the duration of time for issues to be resolved?
    }

    # Open Issues --> What is the number of open issues?
    proj_health[:open_issues] = Issue.where(stm_repo_uuid: "#{repo_uuid}").open.count

    # Closed Issues --> What is the number of closed issues?
    proj_health[:closed_issues] = Issue.where(stm_repo_uuid: "#{repo_uuid}").closed.count

    # Issue Resolution Efficiency --> What is the number of closed issues/number of abandoned issues?
    # abandoned issue = open issue with no no offer and no open contract

    # issues with open contracts
    issues_not_abandoned = []
    issues_contracted = Contract.joins(:issue).open.where('issues.stm_status = ?', 'open').pluck('stm_issue_uuid')
    issues_not_abandoned.concat(issues_contracted)
    issues_offered = Offer.joins(:issue).open.where('issues.stm_status = ?', 'open').pluck('stm_issue_uuid')
    issues_not_abandoned.concat(issues_offered)
    abandoned_issue_count = Issue.open.where('uuid NOT IN (?)', issues_not_abandoned).count


    proj_health[:resolution_efficiency] = proj_health[:closed_issues].to_f / abandoned_issue_count.to_f

    # Open Issue Age --> What is the the age of open issues?
    ages = 0
    issues = 0
    @issues.each do |iss|
      if iss.get_status == 'open'
        ages += iss.get_age
        issues += 1
      end
    end
    proj_health[:open_issue_age] = ages.to_f/issues.to_f

    # Closed Issue Resolution Duration --> What is the duration of time for issues to be resolved?
    ages = 0
    issues = 0
    @issues.each do |iss|
      if iss.status == 'closed'
        ages += iss.get_resolution_days
        issues += 1
      end
    end
    proj_health[:closed_issue_resolution_duration] = ages.to_f/issues.to_f

    return proj_health
  end
  def open_issue(project=1, difficulty=0)
    # puts "new issue #{(@issues.count+1)}"
    if difficulty == 0 then
      difficulty = (1..3).to_a.sample
    end
    iss = Bmxsim_Issue.new((@issues.count+1), get_project_repo_uuid(project), project, difficulty)
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
