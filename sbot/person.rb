#!/usr/bin/env ruby

# (c) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

# Utility function
def difficulty_picker(options)
  # from https://stackoverflow.com/questions/19261061/picking-a-random-option-where-each-option-has-a-different-probability-of-being
  current, max = 0, options.values.inject(:+)
  random_value = rand(max) + 1
  options.each do |key,val|
     current += val
     return key if random_value <= current
  end
end

# ##################################################
# #  FUNDERS
# ##################################################

# template for funders
class Bmxsim_Funder
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
    # function being called by simulation for funder to do something
  end
end

# pays always same amount
class Bmxsim_Funder_FixedPay < Bmxsim_Funder
  def do_work
    # function being called by simulation for funder to do something

    # Create n issues and one offer each
    (0..NUMBER_OF_ISSUES_DAILY_PER_FUNDER).to_a.sample.to_i.times do

      # create issue
      difficulty = difficulty_picker(DIFFICULTIES)
      issue = @tracker.open_issue(@project, difficulty)

      # determine price
      price = PRICES[0]

      # args is a hash
      args  = {
        user_uuid: @uuid,
        price: price,  # always fixed price 1
        volume: 100,
        stm_issue_uuid: issue.uuid,
        expiration: BugmTime.end_of_day(MATURATION_DAYS_IN_FUTURE),
        maturation: BugmTime.end_of_day(MATURATION_DAYS_IN_FUTURE)
      }
      offer = FB.create(:offer_bu, args).offer
      ContractCmd::Cross.new(offer, :expand).project
    end
  end
end


# pays less for difficult tasks
class Bmxsim_Funder_InversePay < Bmxsim_Funder
  def do_work
    # function being called by simulation for funder to do something

    # Create n issues and one offer each
    (0..NUMBER_OF_ISSUES_DAILY_PER_FUNDER).to_a.sample.to_i.times do

      # create issue
      difficulty = difficulty_picker(DIFFICULTIES)
      issue = @tracker.open_issue(@project, difficulty)

      # determine price
      price = PRICES[difficulty-1]

      # args is a hash
      args  = {
        user_uuid: @uuid,
        price: (price).round(2),
        volume: 100,
        stm_issue_uuid: issue.uuid,
        maturation: BugmTime.end_of_day(MATURATION_DAYS_IN_FUTURE)
      }
      offer = FB.create(:offer_bu, args).offer
      ContractCmd::Cross.new(offer, :expand).project
    end
  end
end


# pays more for difficult tasks
class Bmxsim_Funder_CorrelatedPay < Bmxsim_Funder
  def do_work
    # function being called by simulation for funder to do something

    # Create n issues and one offer each
    (0..NUMBER_OF_ISSUES_DAILY_PER_FUNDER).to_a.sample.to_i.times do

      # create issue
      difficulty = difficulty_picker(DIFFICULTIES)
      issue = @tracker.open_issue(@project, difficulty)

      # determine price
      price = PRICES[PRICES.length-difficulty]

      # args is a hash
      args  = {
        user_uuid: @uuid,
        price: (price).round(2),
        volume: 100,
        stm_issue_uuid: issue.uuid,
        maturation: BugmTime.end_of_day(MATURATION_DAYS_IN_FUTURE)
      }
      offer = FB.create(:offer_bu, args).offer
      ContractCmd::Cross.new(offer, :expand).project
    end
  end
end


# pays a random price
class Bmxsim_Funder_RandomPay < Bmxsim_Funder
  def do_work
    # function being called by simulation for funder to do something


    # Create n issues and one offer each
    (0..NUMBER_OF_ISSUES_DAILY_PER_FUNDER).to_a.sample.to_i.times do
      difficulty = difficulty_picker(DIFFICULTIES)
      issue = @tracker.open_issue(@project, difficulty)

      price = PRICES.sample

      # args is a hash
      args  = {
        user_uuid: @uuid,
        price: price,  # randomly choose one of the prices
        volume: 100,
        stm_issue_uuid: issue.uuid,
        maturation: BugmTime.end_of_day(MATURATION_DAYS_IN_FUTURE)
      }
      offer = FB.create(:offer_bu, args).offer
      ContractCmd::Cross.new(offer, :expand).project
    end

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


# ===== Worker: Randomly choose one offer =====
#
class Bmxsim_Worker_Treatment_Random < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue

    # Filter by unassigned, since we want offers that are still up for the taking
    offers = Offer.unassigned
    # then filter by cost<balance to be able to counter the offer
    offers = offers.where('((1-price)*volume) <= '+get_balance.to_s)
    # randomly select an offer UUI
    offer = offers.order('RANDOM()').first

    if !offer.nil? && offer.valid?
      projection = OfferCmd::CreateCounter.new(offer, {user_uuid: @uuid}).project
      counter = projection.offer
      if counter.valid?
        ContractCmd::Cross.new(counter, :expand).project
        # binding.pry
        issue_id = Issue.where(uuid: offer[:stm_issue_uuid]).first[:exid]
        @issue_workingon = @tracker.get_issue(issue_id.to_i)
      end
    end
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
# => 1) Pick an issue arbitrarily. (random)
# => 2) Pick an issue with latest possible maturation date to be
# sure that the task is successfully completed and the unknown reward paid. (risk averse)
#
# More reflective of the current way of peer production, we can try setting
# maturation dates to all be very far out thereby making them irrelevant in
# decision making. Then workes would simply pick issues arbitrarily.
#
# GL reply: Because difficulty levels go up to 3, max days it takes a worker
#           to complete the issue is 3 days. Thus, a worker will only match
#           offers that are at least two days in the future (3 days of work)
#
class Bmxsim_Worker_Treatment_NoMetricsNoPrices_riskAverse < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue

    # then filter by unassigned, since we want offers that are still up for the taking
    offers = Offer.unassigned
    # then filter by cost<balance to be able to counter the offer
    offers = offers.where('((1-price)*volume) <= '+get_balance.to_s)
    # select offer with latest maturation date
    offer = offers.order('maturation_range desc').first

    if !offer.nil? && offer.valid?
      projection = OfferCmd::CreateCounter.new(offer, {user_uuid: @uuid}).project
      counter = projection.offer
      if counter.valid?
        ContractCmd::Cross.new(counter, :expand).project
        # binding.pry
        issue_id = Issue.where(uuid: offer[:stm_issue_uuid]).first.pluck('exid')[0]
        @issue_workingon = @tracker.get_issue(issue_id.to_i)
      end
    end
  end
end


class Bmxsim_Worker_Treatment_NoMetricsNoPrices_random < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue

    # Filter by unassigned, since we want offers that are still up for the taking
    offers = Offer.unassigned
    # then filter by cost<balance to be able to counter the offer
    offers = offers.where('((1-price)*volume) <= '+get_balance.to_s)
    # randomly select an offer
    offer = offers.order('RANDOM()').first

    if !offer.nil? && offer.valid?
      projection = OfferCmd::CreateCounter.new(offer, {user_uuid: @uuid}).project
      counter = projection.offer
      if counter.valid?
        ContractCmd::Cross.new(counter, :expand).project
        # binding.pry
        issue_id = Issue.where(uuid: offer[:stm_issue_uuid]).first.pluck('exid')[0]
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
# => then tie-break with issue with later maturation date. (rewardSeeking)
# => 2) Pick an issue with latest possible maturation date. If
# => more than one such issue then tie-break with issue with highest reward. (riskAverse)
#
class Bmxsim_Worker_Treatment_NoMetricsWithPrices_riskAverse < Bmxsim_Worker
  #version 2
  def do_trade
    # find an open offer to match and associated issue

    # find most profitable offer with latest possible maturation

    # then filter by unassigned, since we want offers that are still up for the taking
    offers = Offer.unassigned
    # then filter by max_cost to counter the offer
    offers = offers.where('((1-price)*volume) <= '+get_balance.to_s)
    # then get the most paying but furthest in the future maturation date
    offer = offers.order('value asc, maturation_range desc').first
    if !offer.nil? && offer.valid?
      projection = OfferCmd::CreateCounter.new(offer, {user_uuid: @uuid}).project
      counter = projection.offer
      if counter.valid?
        ContractCmd::Cross.new(counter, :expand).project
        # binding.pry
        issue_id = Issue.where(uuid: offer[:stm_issue_uuid]).first.pluck('exid')[0]
        @issue_workingon = @tracker.get_issue(issue_id.to_i)
      end
    end

  end
end

class Bmxsim_Worker_Treatment_NoMetricsWithPrices_rewardSeeking < Bmxsim_Worker
  #version 1
  def do_trade
    # find an open offer to match and associated issue

    # find soon outpaying offer

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
    if !offer.nil? && offer.valid?
      projection = OfferCmd::CreateCounter.new(offer, {user_uuid: @uuid}).project
      counter = projection.offer
      if counter.valid?
        ContractCmd::Cross.new(counter, :expand).project
        # binding.pry
        issue_id = Issue.where(uuid: offer[:stm_issue_uuid]).first.pluck('exid')[0]
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
# => Consider the health metric, resolution_efficiency. Redefine it as
# => resolution_efficiency = number of closed issues / (number of closed +
# => number of abandoned issues) to avoid divide by zero problems. This term
# => gives us a fraction that we can use in the following way: the higher the
# => value the easier the task and fractional values lie between 0 and 1. With
# => 3 levels of difficulty we can simply segment the resolution_efficiency's
# => [0, 1] interval into 3 parts. Thus [0-0.3] implies level 3, (0.3, 0.7]
# => implies level 2, and (0.7, 1] implies level 1. We can leave it like this or
# => introduce a probabilistic layer. Consider the 3 cases:
# => 1) resolution_efficiency lies in [0-0.3]. Generate a random number in the
# => interval [0, 1]. If the number <= 0.9 then level 3 else level 2.
# => 2) resolution_efficiency lies in (0.3, 0.7]. Generate a random number in the
# => interval [0, 1]. If the number <= 0.8 then level 2, else either level 3 or
# => 1 with equal probability.
# => 3) resolution_efficiency lies in [0.7-1]. Generate a random number in the
# => interval [0, 1]. If the number <= 0.9 then level 1 else level 2.
# => Note that we are assuming that there can be an error in inferring get_difficulty
# => from the health metrics and that error is w.r.t. "adjacent" levels. There
# => can be more natural variations of this scheme but this is a simple start.
#
# => With the health metric, closed_issue_resolution_duration the difficulty
# => levels can be interpreted directly (how long it took == difficulty level).
#
# => The health metric, open_issue_age, may be interpreted similarly to
# => resolution_efficiency.
#
class Bmxsim_Worker_Treatment_HealthMetricsNoPrices < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue

    # difficulty level = probabilistic (start with resolution efficiency)

    # health metrics are used to rank projects on each metric
    # normalized [0..1] for each metric +. add them together and calculate global rank
# --> 1 best, 0 worst
# --> this makes sure we always have a project at 1
# --> if projects are close together in one metric, then it will be weighted less compared to another metric

#  alternatively: rank separtely
#  -->

# --> future work: workers learn, which metric is most indicative of difficulty

# focus on issue resolution efficiency and closed issue resolution duration
#  --> flat out ranking
# randomize other three
#  --> create dividing threashold, percentiles

# MR: Global ranking of projects: for each project take the average of the
# normalized scores for the various health metric (make sure the scores all
# run in the same direction, e.g., 0 implies easy and 1 implies difficult).
# Thus workers can select according to the global ranking or the separate metric
# tankings of the projects.



    # 1st: guess the average difficulty level of issues (on a project)
    # filter out issues that are expected to not be completed on time
    #  --> where statement for each project filtering minimum maturation date
    # 2nd:
    # option 1: random selection
    # option 2: latest maturation date
    # option 3: soonest maturation date


    # select first by maturation range, at least 2 days in the future
    matures_after_days = 2
    #   the 90 day end is chosen arbitrarily
    offers = Offer.by_maturation_range(BugmTime.end_of_day(matures_after_days)..BugmTime.end_of_day(90))


  end
end


# ===== Worker: Yes Health Metrics, No Market Metrics, Yes Prices =====
#
class Bmxsim_Worker_Treatment_HealthMetricsWithPrices < Bmxsim_Worker
  def do_trade
    # find an open offer to match and associated issue


  # same as without price and then choose most valuable (highest reward, not yet discounted of reward)

    projects_health = @tracker.get_project_health_all_projects
    projects_health.each do |proj_h|
      puts proj_h[:resolution_efficiency]
    end
  end
end

# Ignore everything down for now!

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
