#!/usr/bin/env ruby

# (c) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

require File.expand_path("~/src/bugmark/config/environment")

class Bmxsim_Issue
  def initialize(id, repo_uuid, project=1, difficulty=1)
    @status = '   open'  # closed or open
    @progress = 0  # percentage of completion
    @project = project  # in the simulation we have different projects
    @difficulty = difficulty  # difficulty level of issue
    @id = id  # id of this issue
    @bmx_issue = FB.create(:issue, stm_repo_uuid: repo_uuid, exid: id, stm_status: "open").issue
    @uuid = @bmx_issue.uuid
  end
  def uuid
    @uuid
  end
  def close
    @status = 'closed'
    IssueCmd::Sync.new({exid: @id, stm_status: "closed"}).project
  end
  def reopen
    @status = '   open '
    IssueCmd::Sync.new({exid: @id, stm_status: "open"}).project
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
