#!/usr/bin/env ruby

# (c) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

# require File.expand_path("~/src/exchange/config/environment")

class Bmxsim_Issue
  def initialize(id, tracker_uuid, project=1, difficulty=1)
    @status = 'open'  # closed or open
    @progress = 0  # percentage of completion
    @project = project  # in the simulation we have different projects
    @difficulty = difficulty  # difficulty level of issue
    @id = id  # id of this issue
    @uuid = FB.create(:issue, stm_tracker_uuid: tracker_uuid, exid: id, stm_status: "open").issue.uuid
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
  def get_project
    @project
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
    # @project_bmx_tracker = []
    @project_bmx_tracker_uuid = {}
    # puts "New Issue tracker, with uuid: #{@uuid}"
  end
  def uuid
    @uuid
  end
  def add_project(proj_number)

    bmx_tracker = TrackerCmd::Create.new({name: 'TestTracker'+proj_number.to_s, type: 'Tracker::Test'}).project.tracker
    # bmx_tracker = FB.create(:tracker).tracker
    # @project_bmx_tracker.insert(proj_number, bmx_tracker)
    @project_bmx_tracker_uuid[proj_number] = bmx_tracker.uuid
    return bmx_tracker.uuid
  end
  def get_projects
    @project_bmx_tracker_uuid
  end
  def get_project_tracker_uuid(proj_number)
    @project_bmx_tracker_uuid[proj_number]
  end
  def get_project_health(proj_number)
    tracker_uuid = get_project_tracker_uuid(proj_number)
    proj_health = {
      open_issues: nil,  # What is the number of open issues?
      closed_issues: nil,  # What is the number of closed issues?
      resolution_efficiency: nil, # What is the number of closed issues/number of abandoned issues?
      open_issue_age: nil,  # What is the the age of open issues?
      closed_issue_resolution_duration: nil  # What is the duration of time for issues to be resolved?
    }

    # Open Issues --> What is the number of open issues?
    proj_health[:open_issues] = Issue.where(stm_tracker_uuid: "#{tracker_uuid}").open.count.to_f
    proj_health[:open_issues] = 0.0 if proj_health[:open_issues].nan?

    # Closed Issues --> What is the number of closed issues?
    proj_health[:closed_issues] = Issue.where(stm_tracker_uuid: "#{tracker_uuid}").closed.count.to_f
    proj_health[:closed_issues] = 0.0 if proj_health[:closed_issues].nan?

    # Issue Resolution Efficiency --> What is the number of closed issues/number of abandoned issues?
    # abandoned issue = open issue with no no offer and no open contract

    # issues with open contracts
    abandoned_issue_count = Issue.open.where.not(uuid: Offer.open.where('expiration > ?', BugmTime.now).select('stm_issue_uuid')).where.not(uuid: Contract.open.select('stm_issue_uuid')).count.to_f
    abandoned_issue_count = 0.0 if abandoned_issue_count.nan?
    # abandoned_issue_count = Issue.open.where('uuid NOT IN (?)', Offer.open.where('expiration > ?', BugmTime.now).select('stm_issue_uuid')).where('uuid NOT IN (?)', Contract.open.select('stm_issue_uuid')).count


    proj_health[:resolution_efficiency] = (proj_health[:closed_issues] / (proj_health[:closed_issues] + abandoned_issue_count)).to_f
    proj_health[:resolution_efficiency] = 0.0 if proj_health[:resolution_efficiency].nan?

    # Open Issue Age --> What is the the age of open issues?
    ages = 0
    issues = 0
    @issues.each do |iss|
      if iss.get_status == 'open' && iss.get_project == proj_number
        ages += iss.get_age
        issues += 1
      end
    end
    if issues.to_f == 0 then
      proj_health[:open_issue_age] = 0.0
    else
      proj_health[:open_issue_age] = ages.to_f/issues.to_f
    end

    # Closed Issue Resolution Duration --> What is the duration of time for issues to be resolved?
    ages = 0
    issues = 0
    @issues.each do |iss|
      if iss.get_status == 'closed' && iss.get_project == proj_number
        ages += iss.get_resolution_days
        issues += 1
      end
    end
    if issues.to_f == 0 then
      proj_health[:closed_issue_resolution_duration] = 0
    else
      proj_health[:closed_issue_resolution_duration] = ages.to_f/issues.to_f
    end

    return proj_health
  end
  def get_project_health_all_projects
    # track the extreme values
    max_open_issues = 0.0
    max_closed_issues = 0.0
    min_resolution_efficiency = 1.0
    max_open_issue_age = 0.0
    max_closed_issue_resolution_duration = 0.0
    max_sum_norm = 0.0
    max_sum_rank = 0

    # get project health
    projects = {}
    get_projects.to_a.each do |proj_number,tracker_uuid|
      # tracker_uuid = get_project_tracker_uuid(proj_number)
      projects[tracker_uuid] = get_project_health(proj_number)
      # Update extreme values
      max_open_issues = projects[tracker_uuid][:open_issues].to_f if max_open_issues < projects[tracker_uuid][:open_issues].to_f
      max_closed_issues = projects[tracker_uuid][:closed_issues].to_f if max_closed_issues < projects[tracker_uuid][:closed_issues].to_f
      min_resolution_efficiency = projects[tracker_uuid][:resolution_efficiency].to_f if min_resolution_efficiency > projects[tracker_uuid][:resolution_efficiency].to_f
      max_open_issue_age = projects[tracker_uuid][:open_issue_age].to_f if max_open_issue_age < projects[tracker_uuid][:open_issue_age].to_f
      max_closed_issue_resolution_duration = projects[tracker_uuid][:closed_issue_resolution_duration].to_f if max_closed_issue_resolution_duration < projects[tracker_uuid][:closed_issue_resolution_duration].to_f
    end

    # Normalize health metrics for each Project
    get_projects.to_a.each do |proj_number,tracker_uuid|
      projects[tracker_uuid][:sum_norm] = 0.0
      projects[tracker_uuid][:sum_rank] = 0

      # OPEN ISSUES ----------------------------------------------------------

      unless max_open_issues == 0.0 then
        # 1 = no open issues (better)
        # 0 = most open issues (worse)
        projects[tracker_uuid][:norm_open_issues] = 1.0 - projects[tracker_uuid][:open_issues].to_f / max_open_issues
      else
        projects[tracker_uuid][:norm_open_issues] = 0.0
      end
      projects[tracker_uuid][:sum_norm] += projects[tracker_uuid][:norm_open_issues]

      # CLOSED ISSUES --------------------------------------------------------

      unless max_closed_issues == 0.0 then
        # 1 = most open issues (better)
        # 0 = no closed issues (worse)
        projects[tracker_uuid][:norm_closed_issues] = projects[tracker_uuid][:closed_issues].to_f / max_closed_issues
      else
        projects[tracker_uuid][:norm_closed_issues] = 0.0
      end
      projects[tracker_uuid][:sum_norm] += projects[tracker_uuid][:norm_closed_issues]

      # RESOLUTION EFFICIENCY ------------------------------------------------

      # 1 = all issues closed and none abandoned (better)
      # 0 = no issues closed and all abandoned (worse)
      projects[tracker_uuid][:norm_resolution_efficiency] = projects[tracker_uuid][:resolution_efficiency].to_f # already normalized
      projects[tracker_uuid][:sum_norm] += projects[tracker_uuid][:norm_resolution_efficiency]

      # OPEN ISSUE AGE -------------------------------------------------------

      unless max_open_issue_age == 0.0 then
        # 1 = open issues are 0 days old (best)
        # 0 = open issues are very old (worse)
        projects[tracker_uuid][:norm_open_issue_age] = 1.0 - projects[tracker_uuid][:open_issue_age].to_f / max_open_issue_age
      else
        projects[tracker_uuid][:norm_open_issue_age] = 0.0
      end
      projects[tracker_uuid][:sum_norm] += projects[tracker_uuid][:norm_open_issue_age]

      # CLOSED ISSUE RESOLUTION DURATION -------------------------------------

      unless max_closed_issue_resolution_duration == 0.0 then
        # 1 = all issues are closed immediately (better)
        # 0 = max average time to close issues (worse)
        projects[tracker_uuid][:norm_closed_issue_resolution_duration] = 1.0 - projects[tracker_uuid][:closed_issue_resolution_duration].to_f / max_closed_issue_resolution_duration
      else
        projects[tracker_uuid][:norm_closed_issue_resolution_duration] = 0.0
      end
      projects[tracker_uuid][:sum_norm] += projects[tracker_uuid][:norm_closed_issue_resolution_duration]
      max_sum_norm = projects[tracker_uuid][:sum_norm] if max_sum_norm < projects[tracker_uuid][:sum_norm]
    end

    # get rank for open_issues and add to project health
    sort_open_issues = projects.sort_by {|key, value| value[:norm_open_issues].to_f}
    rank = 0
    prev_val = nil
    sort_open_issues.each do |proj|
      rank += 1 unless prev_val.eql? proj[1][:norm_open_issues]
      prev_val = proj[1][:norm_open_issues]
      projects[proj[0]][:rank_open_issues] = rank
      projects[proj[0]][:sum_rank] += rank
    end

    # get rank for closed_issues and add to project health
    sort_closed_issues = projects.sort_by {|key, value| value[:norm_closed_issues].to_f}
    rank = 0
    prev_val = nil
    sort_closed_issues.each do |proj|
      rank += 1 unless prev_val.eql? proj[1][:norm_closed_issues]
      prev_val = proj[1][:norm_closed_issues]
      projects[proj[0]][:rank_closed_issues] = rank
      projects[proj[0]][:sum_rank] += rank
    end

    # get rank for resolution_efficiency and add to project health
    sort_resolution_efficiency = projects.sort_by {|key, value| value[:norm_resolution_efficiency].to_f}
    rank = 0
    prev_val = nil
    sort_resolution_efficiency.each do |proj|
      rank += 1 unless prev_val.eql? proj[1][:norm_resolution_efficiency]
      prev_val = proj[1][:norm_resolution_efficiency]
      projects[proj[0]][:rank_resolution_efficiency] = rank
      projects[proj[0]][:sum_rank] += rank
    end

    # get rank for open_issue_age and add to project health
    sort_open_issue_age = projects.sort_by {|key, value| value[:norm_open_issue_age].to_f}
    rank = 0
    prev_val = nil
    sort_open_issue_age.each do |proj|
      rank += 1 unless prev_val.eql? proj[1][:norm_open_issue_age]
      prev_val = proj[1][:norm_open_issue_age]
      projects[proj[0]][:rank_open_issue_age] = rank
      projects[proj[0]][:sum_rank] += rank
    end

    # get rank for closed_issue_resolution_duration and add to project health
    sort_closed_issue_resolution_duration = projects.sort_by {|key, value| value[:norm_closed_issue_resolution_duration].to_f}
    rank = 0
    prev_val = nil
    sort_closed_issue_resolution_duration.each do |proj|
      rank += 1 unless prev_val.eql? proj[1][:norm_closed_issue_resolution_duration]
      prev_val = proj[1][:norm_closed_issue_resolution_duration]
      projects[proj[0]][:rank_closed_issue_resolution_duration] = rank
      projects[proj[0]][:sum_rank] += rank
      max_sum_rank = projects[proj[0]][:sum_rank] if max_sum_rank < projects[proj[0]][:sum_rank]
    end

    # include extreme values in output
    projects[:max_open_issues] = max_open_issues
    projects[:max_closed_issues] = max_closed_issues
    projects[:min_resolution_efficiency] = min_resolution_efficiency
    projects[:max_open_issue_age] = max_open_issue_age
    projects[:max_closed_issue_resolution_duration] = max_closed_issue_resolution_duration
    projects[:max_sum_norm] = max_sum_norm
    projects[:max_sum_rank] = max_sum_rank

    return projects
  end
  def open_issue(project=1, difficulty=0)
    # puts "new issue #{(@issues.count+1)}"
    if difficulty == 0 then
      difficulty = (1..3).to_a.sample
    end
    iss = Bmxsim_Issue.new((@issues.count+1), get_project_tracker_uuid(project), project, difficulty)
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
