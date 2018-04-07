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
    # @open_offer_bu = []
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
    @progress += [(100.0*effort/@difficulty).ceil,100].min
    # close issue, if work is complete
    close unless @progress < 100
  end
  # def add_offer_bu(offer)
  #   offer[:issue_id] = @id
  #   @open_offer_bu.push(offer)
  # end
  # def get_highest_paying_offer(max_cost=0)
  #   offer = nil
  #   @open_offer_bu.each do |off|
  #     off[:offer].reload
  #     if off[:offer][:status] != "open"
  #       remove_offer(off)
  #       next
  #     end
  #     offer = off if offer.nil?
  #     if max_cost == 0 || max_cost > ((1-off[:price])*off[:volume])
  #       # binding.pry
  #       offer = off if offer[:offer][:value]<off[:offer][:value]
  #     end
  #   end
  #   return offer
  # end
  # def remove_offer(offer)
  #   @open_offer_bu.delete(offer)
  # end
  # def remove_offer_by_uuid(uuid)
  #   offer = nil
  #   @open_offer_bu.each do |off|
  #     offer = off if off[:offer][:uuid] == uuid
  #   end
  # end
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

    bmx_repo = RepoCmd::Sync.new({name: 'TestRepo'+proj_number.to_s, type: 'Repo::Test'}).project.repo
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
  # def get_highest_paying_offer(max_cost=0)
  #   offer = nil
  #   @issues.each do |iss|
  #     iss_off = iss.get_highest_paying_offer(max_cost)
  #     unless iss_off.nil?
  #       offer = iss_off if offer.nil?
  #       offer = iss_off if offer[:offer][:value] < iss_off[:offer][:value]
  #     end
  #   end
  #   return offer
  # end
  def get_highest_paying_offer_db(max_cost=0)
    # select first by maturation range, at least 2 days in the future
    #   the 90 day end is chosen arbitrarily
    offers = Offer.by_maturation_range(BugmTime.end_of_day(2)..BugmTime.end_of_day(90))
    # then filter by unassigned, since we want offers that are still up for the taking
    offers = offers.unassigned
    # then filter by max_cost to counter the offer
    offers = offers.where('((1-price)*volume) <= '+max_cost.to_s)
    # then get the most paying
    offer = offers.order('value desc').first
    return nil unless offer.valid?
    return offer
  end
  def remove_offer(offer)
    get_issue(offer[:issue_id]).remove_offer(offer)
  end
  def remove_offer_by_uuid(issue_id, uuid)
    get_issue(issue_id).remove_offer_by_uuid(uuid)
  end
end
