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
    # puts "New issue (#{@id}) with uuid: #{@uuid}"
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
  def get_difficulty
    @difficulty
  end
  def work(effort)
    @progress = [(effort/@difficulty*100).ceil,1].min
  end
end

class Bmxsim_IssueTracker
  def initialize(bmx_repo)
    @issues = []
    @bmx_repo = bmx_repo
    @uuid = @bmx_repo.uuid
    # puts "New Issue tracker, with uuid: #{@uuid}"
  end
  def uuid
    @uuid
  end
  def open_issue(project=1, difficulty=1)
    # puts "new issue #{(@issues.count+1)}"
    iss = Bmxsim_Issue.new((@issues.count+1), @uuid, project, difficulty)
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
