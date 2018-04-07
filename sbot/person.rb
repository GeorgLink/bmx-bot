#!/usr/bin/env ruby

# (c) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

# ##################################################
# #  FUNDERS
# ##################################################

# pays less for difficult tasks
class Bmxsim_Funder_InversePay
  def initialize(bmx_user, issue_tracker, skill=nil)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
    @project = 1
  end
  def uuid
    @uuid
  end
  def do_work
    # create twelve issues
    (1..1).to_a.each do
      issue = @tracker.open_issue(@project)

      # args is a hash
      args  = {
        user_uuid: @uuid,
        price: (1.0/(issue.get_difficulty+1)).round(2),
        volume: 100,
        stm_issue_uuid: issue.uuid,
        maturation: BugmTime.next_week_ends[1]
      }
      offer = FB.create(:offer_bu, args).offer
      ContractCmd::Cross.new(offer, :expand).project
      args[:offer] = offer
      issue.add_offer_bu(args)
      # binding.pry
    end
  end
  def do_trade
    # decide what to trade on bugmark
  end
end

# pays more for difficult tasks
class Bmxsim_Funder_CorrelatedPay
  def initialize(bmx_user, issue_tracker, skill=nil)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
    @project = 2
  end
  def uuid
    @uuid
  end
  def do_work
    # decide what issue to work on
  end
  def do_trade
    # decide what to trade on bugmark
  end
end

# pays always same amount
class Bmxsim_Funder_FixedPay
  def initialize(bmx_user, issue_tracker, proj_number)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @project = proj_number
    @proj_repo_uuid = @tracker.add_project(proj_number)
  end
  def uuid
    @uuid
  end
  def do_work

    # Create n issues and one offer each
    n = 1
    (1..n).to_a.each do
      issue = @tracker.open_issue(@project)

      # args is a hash
      args  = {
        user_uuid: @uuid,
        price: 1,  # always fixed price 1
        volume: 100,
        stm_issue_uuid: issue.uuid,
        maturation: BugmTime.end_of_day(7)  # always 7 days in the future
      }
      offer = FB.create(:offer_bu, args).offer
      ContractCmd::Cross.new(offer, :expand).project
      # args[:offer] = offer
      # issue.add_offer_bu(args)
    end
  end
  def do_trade
    # decide what to trade on bugmark
  end
end


# pays a random price
class Bmxsim_Funder_RandomPay
  def initialize(bmx_user, issue_tracker, skill=nil)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
    @project = 4
  end
  def uuid
    @uuid
  end
  def do_work
    # decide what issue to work on
  end
  def do_trade
    # decide what to trade on bugmark
  end
end



# ##################################################
# #  WORKERS
# ##################################################


# template for workers
class Bmxsim_Worker
  def initialize(bmx_user, issue_tracker, skill=nil, name='workerx')
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
    @issue_workingon = nil
    @name = name
    @last_issue
  end
  def get_name
    @name
  end
  def uuid
    @uuid
  end
  def get_skill
    @skill
  end
  def get_balance
    @bmx_user.reload
    @bmx_user[:balance]
  end
  def issue_status
    if @last_issue.nil?
      return 'no issue'
    end
    maturation = Position.joins(contract: :issue).where(user_uuid: "#{@uuid}").where("issues.uuid = '#{@last_issue.uuid}'").pluck("maturation")
    @last_issue.uuid
    return "#{@last_issue.get_progress}% #{@last_issue.get_status}, due: #{maturation[0]}"
  end
  def do_work
    # do work
    @last_issue = nil
    # make sure to have an issue to work on
    do_trade if @issue_workingon.nil?
    unless @issue_workingon.nil?
      # do the work
      @last_issue = @issue_workingon
      @issue_workingon.work(@skill)
      # get ready for new issue, if current issue was closed
      @issue_workingon = nil if @issue_workingon.get_status == 'closed'
    end
  end
  def do_trade
    # find an offer and determine what issue to work on
  end
end


# ===== Worker: No Metrics, No Prices =====
#
# MR: In the initial simulation all workers are modeled as having the same
# skill level: skill level 1. Here the number of units of time required to
# complete a task increases with the difficulty level of the task. That is,
# difficulty levels 1, 2, 3 take 1, 2, 3 units of time (days) respectively. We also
# assume that there is no time limit facing a worker to complete a set of
# tasks in say 1 week. If there were such a time limit then workers would
# need to preselect the set of issues whose maturation dates fall within the
# remainaining time (database query). Instead workers are time constrained
# only by individual issue maturation dates.
#
# In this treatment workers are "in the dark". They have no price signals
# and no metrics. They do, however, see the maturation date of each issue.
# Because workers know their skill level, they reason in one of these ways:
# => 1) Pick an issue arbitrarily.
# => 2) Pick an issue with maturation date >= 3 units of time (days) from now to be
# sure that the task is successfully completed and the unknown reward paid.
#
# More reflective of the current way of peer production, we can try setting
# maturation dates to all be very far out thereby making them irrelevant in
# decision making. Then workes would simply pick issues arbitrarily.
#
# GL reply: Because difficulty levels go up to 3, max days it takes a worker
#           to complete the issue is 3 days. Thus, a worker will only match
#           offers that are at least two days in the future (3 days of work)
#
class Bmxsim_Worker_Treatment_NoMetricsNoPrices < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue

    # select first by maturation range, at least 2 days in the future
    matures_after_days = 2
    #   the 90 day end is chosen arbitrarily
    offers = Offer.by_maturation_range(BugmTime.end_of_day(matures_after_days)..BugmTime.end_of_day(90))
    # then filter by unassigned, since we want offers that are still up for the taking
    offers = offers.unassigned
    # then filter by cost<balance to be able to counter the offer
    offers = offers.where('((1-price)*volume) <= '+get_balance.to_s)
    # get all UUIDs
    offers_uuid = offers.pluck('uuid')
    # randomly select an offer
    offer = Offer.where(uuid: offers_uuid.sample).first

    if offer.valid?
      projection = OfferCmd::CreateCounter.new(offer, {user_uuid: @uuid}).project
      counter = projection.offer
      if counter.valid?
        ContractCmd::Cross.new(counter, :expand).project
        # binding.pry
        issue_id = Issue.where(uuid: offer[:stm_issue_uuid]).pluck('exid')[0]
        @issue_workingon = @tracker.get_issue(issue_id.to_i)
      end
    end
  end
end


# ===== Worker: No Metrics, Yes Prices =====

# decide what issue to work on
# MR: In the absence of any metrics, workers decide myopically according
# to the signals available to them, namely price and maturation date, as
# well as their own knowledge of their skill level.
#
# => Given a set of existing, open issues, decide in one of these ways:
# => 1) Pick an issue with the highest reward. If more than one such issue
# => then tie-break with issue with later maturation date.
# => 2) Pick an issue with maturation date >= 3 units of time from now. If
# => more than one such issue then tie-break with issue with highest reward.
#
class Bmxsim_Worker_Treatment_NoMetricsWithPrices < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue

    # find most profitable and soon outpaying offer

    # select first by maturation range, at least 2 days in the future
    matures_after_days = 2
    #   the 90 day end is chosen arbitrarily
    offers = Offer.by_maturation_range(BugmTime.end_of_day(matures_after_days)..BugmTime.end_of_day(90))
    # then filter by unassigned, since we want offers that are still up for the taking
    offers = offers.unassigned
    # then filter by max_cost to counter the offer
    offers = offers.where('((1-price)*volume) <= '+get_balance.to_s)
    # then get the most paying
    offer = offers.order('value asc').first
    if offer.valid?
      projection = OfferCmd::CreateCounter.new(offer, {user_uuid: @uuid}).project
      counter = projection.offer
      if counter.valid?
        ContractCmd::Cross.new(counter, :expand).project
        # binding.pry
        issue_id = Issue.where(uuid: offer[:stm_issue_uuid]).pluck('exid')[0]
        @issue_workingon = @tracker.get_issue(issue_id.to_i)
      end
    end

  end
end


# ===== Worker: Yes Health Metrics, No Market Metrics, No Prices =====
#
# MR: Not fully fleshed out yet. The idea is as follows:
# => Health Metrics used to compute a "difficulty estimate or likelihood",
# => referred to as diff_estimate. Workers choose to work on issues where
# => the maturation date allows sufficient time given diff_estimate. This is
# => similar to the NoPricesNoMetrics_FullTaskInfoNoTimeLimit treatment.
#
class Bmxsim_Worker_Treatment_HealthMetricsNoPrices < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue
  end
end


# ===== Worker: Yes Health Metrics, No Market Metrics, Yes Prices =====
#
# MR: Not fully fleshed out yet. The idea is as follows:
# => Health Metrics used to compute a "difficulty estimate or likelihood",
# => referred to as diff_estimate. Workers choose to work on issues with the
# => highest reward subject to the maturation date allowing sufficient time
# => given diff_estimate.
#
class Bmxsim_Worker_Treatment_HealthMetricsWithPrices < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue
  end
end


class Bmxsim_Worker_Treatment_MarketMetrics < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue
  end
end


class Bmxsim_Worker_Treatment_BothMetrics < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue
  end
end


# MR: No time limit to complete all tasks so no packing problem to solve.
# Instead workers pick the issue where the maturation date and difficulty
# level being such that there is enough time to complete the issue and get
# paid. If not enough time for any issues then workers do not work! Why
# bother working knowing you will not be paid?
class Bmxsim_Worker_Treatment_NoPricesNoMetrics_FullTaskInfoNoTimeLimit < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue
  end
end


# MR: full task information means that workers know the difficulty of the
# open issues. Workers are, however, myopic. So at each decision, solve the
# packing problem with "eligible" issues and pick first issue in the
# solution (highest reward issue greedily)
class Bmxsim_Worker_Treatment_NoPricesNoMetrics_FullTaskInfoWithTimeLimit < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue
  end
end
