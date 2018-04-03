class Person
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
