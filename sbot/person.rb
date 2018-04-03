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

# pays more for difficult tasks
class Bmxsim_Funder_CorrelatedPay
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

# pays always same amount
class Bmxsim_Funder_FixedPay
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


# pays a random price
class Bmxsim_Funder_RandomPay
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

class Bmxsim_Worker_Treatment_NoMetrics
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
