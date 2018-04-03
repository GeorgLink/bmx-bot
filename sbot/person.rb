#!/usr/bin/env ruby

# (c) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

#template for other persons
class Bmxsim_Person
  def initialize(bmx_user, issue_tracker, skill=nil)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
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
    # decide what issue to work on
    # create twelve issues
    (1..12).to_a.each do
      issue = @tracker.open_issue(@project)

      # args is a hash
      args  = {
        user_uuid: @uuid,
        price: (1/(issue.get_difficulty+1).round(2)),
        volume: 100,
        stm_issue_uuid: issue.uuid,
        maturation: BugmTime.next_week_ends[2]
      }
      offer = FB.create(:offer_bu, args).offer
      ContractCmd::Cross.new(offer, :expand).project
      args[:offer] = offer
      issue.add_offer_bu(args)
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
  def initialize(bmx_user, issue_tracker, skill=nil)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
    @project = 3
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

class Bmxsim_Worker_Treatment_NoMetrics
  def initialize(bmx_user, issue_tracker, skill=nil)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
    @issue_workingon = nil
  end
  def uuid
    @uuid
  end
  def do_work
    # decide what issue to work on

    # make sure to have an issue to work on
    do_trade if @issue_workingon.nil?
    unless @issue_workingon.nil?
      # do the work
      @issue_workingon.work(@skill)
      # get ready for new issue, if current issue was closed
      @issue_workingon = nil if @issue_workingon.get_status == 'closed'
    end
  end
  def do_trade
    # decide what to trade on bugmark
    offer = @tracker.get_highest_paying_offer
    unless offer.nil?
      projection = OfferCmd::CreateCounter.new(offer[:offer], {user_uuid: @uuid}).project
      puts projection
      unless projection.nil?
        counter = projection.offer
        puts counter
        ContractCmd::Cross.new(counter, :expand).project
      end
    end

  end
end


class Bmxsim_Worker_Treatment_HealthMetrics
  def initialize(bmx_user, issue_tracker, skill=nil)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
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


class Bmxsim_Worker_Treatment_MarketMetrics
  def initialize(bmx_user, issue_tracker, skill=nil)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
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


class Bmxsim_Worker_Treatment_BothMetrics
  def initialize(bmx_user, issue_tracker, skill=nil)
    @bmx_user = bmx_user
    @uuid = bmx_user.uuid
    @tracker = issue_tracker
    @skill = skill
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
