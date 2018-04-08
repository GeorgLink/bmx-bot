#!/usr/bin/env ruby

# (c) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

require 'benchmark'
time = Benchmark.measure do
  PROCNAME = "cscw_bot"
  Process.setproctitle(PROCNAME)

  # for C-c
  trap "SIGINT" do
    puts "\nExiting"
    exit 130
  end

  # for "pkill -f fast_bot_buy"
  trap "SIGTERM" do
    puts "TERMINATED #{Time.now}"
    STDOUT.flush
    exit 130
  end

  # SIMULATION PARAMETERS
  NUMBER_OF_WORKERS = 3
  NUMBER_OF_FUNDERS = 1  # equals number of projects
  NUMBER_OF_ISSUES_DAILY_PER_FUNDER = 3  # equals number of offers created; #issue=#offer
  MATURATION_DAYS_IN_FUTURE = 5 # end of:  0 = today, 1 = tomorrow
  FUNDER_STARTING_BALANCE = 100000000
  WORKER_STARTING_BALANCE = 0
  WORKER_SKILLS = [1]  # ability to randomly create workers with different skills
  RUN_SIMULATION_DAYS = 8

  # output
  BMXSIM_OUTPUT = 1  # 0 no output, 1 slim output, 9 detailed output

  # run in turbo mode
  BMX_SAVE_EVENTS  = "FALSE"
  BMX_SAVE_METRICS = "FALSE"

  # global day variable
  $sim_day = 0

  require 'io/console'
  def continue_story
    print "press any key"
    STDIN.getch
    print "            \r" # extra space to overwrite in case next sentence is short
  end


  puts "----- BUGMARK BOT -------------------------------------------"
  puts "START #{Time.now} | C-c to exit"
  puts "Process Name: #{PROCNAME}" if BMXSIM_OUTPUT > 0
  puts "Loading Environment..." if BMXSIM_OUTPUT > 0
  STDOUT.flush

  require File.expand_path("~/src/bugmark/config/environment")

  # delete all host data and create admin user
  BugmHost.reset
  BugmTime.set_day_offset(-1 * RUN_SIMULATION_DAYS)

  puts "Simulate #{RUN_SIMULATION_DAYS}, starting on #{BugmTime.now}"

  # simulation classes
  require_relative 'issuetracker'
  require_relative 'person'

  # create Issue Tracker
  issue_tracker = Bmxsim_IssueTracker.new

  # create funders and workers
  funders = []
  (1..NUMBER_OF_FUNDERS).to_a.each do |funder_id|
    STDOUT.write "\rcreate funders: #{funder_id} / #{NUMBER_OF_FUNDERS}"  if BMXSIM_OUTPUT > 0
    funder = FB.create(:user, email: "funder#{funder_id}@bugmark.net", balance: FUNDER_STARTING_BALANCE).user
    funders.push(Bmxsim_Funder_FixedPay.new(funder, issue_tracker, funder_id))
    # case funder_id
    # when 1
    #   funders.push(Bmxsim_Funder_InversePay.new(funder, issue_tracker))
    # when 2
    #   funders.push(Bmxsim_Funder_CorrelatedPay.new(funder, issue_tracker))
    # when 3
    #   funders.push(Bmxsim_Funder_FixedPay.new(funder, issue_tracker))
    # else
    #   funders.push(Bmxsim_Funder_RandomPay.new(funder, issue_tracker))
    # end
  end
  puts "" if BMXSIM_OUTPUT > 0
  workers = []
  (1..NUMBER_OF_WORKERS).to_a.each do |worker_id|
    STDOUT.write "\rcreate workers: #{worker_id} / #{NUMBER_OF_WORKERS}" if BMXSIM_OUTPUT > 0
    worker = FB.create(:user, email: "worker#{worker_id}@bugmark.net", balance: WORKER_STARTING_BALANCE).user
    # skill = (1..3).to_a.sample
    skill = WORKER_SKILLS.sample
    workers.push(Bmxsim_Worker_Treatment_NoMetricsWithPrices.new(worker, issue_tracker, skill, "w#{worker_id}"))
    # group_size = NUMBER_OF_WORKERS/4
    # case worker_id
    # when (1..group_size)
    #   workers.push(Bmxsim_Worker_Treatment_NoMetrics.new(worker, issue_tracker, skill))
    # when ((group_size+1)..(2*group_size))
    #   workers.push(Bmxsim_Worker_Treatment_HealthMetrics.new(worker, issue_tracker, skill))
    # when ((2*group_size+1)..(3*group_size))
    #   workers.push(Bmxsim_Worker_Treatment_MarketMetrics.new(worker, issue_tracker, skill))
    # else
    #   workers.push(Bmxsim_Worker_Treatment_BothMetrics.new(worker, issue_tracker, skill))
    # end
  end
  puts "" if BMXSIM_OUTPUT > 0

  # loop for each day
  (1..RUN_SIMULATION_DAYS).to_a.each do |day|
    puts "Day #{day}: #{BugmTime.now}"  if BMXSIM_OUTPUT > 0
    $sim_day = day
    # call funders in a random order
    funders.shuffle.each do |funder|
      print "f" if BMXSIM_OUTPUT > 0 && BMXSIM_OUTPUT < 9
      funder.do_work
      puts "funder[#{funder.get_name}](#{funder.get_balance})"  if BMXSIM_OUTPUT > 8
    end
    # call workers in a random order
    workers.shuffle.each do |worker|
      print "w"  if BMXSIM_OUTPUT > 0 && BMXSIM_OUTPUT < 9
      worker.do_work
      puts "worker[#{worker.get_name}:#{worker.get_skill}](#{worker.get_balance}): #{worker.issue_status}" if BMXSIM_OUTPUT > 8
    end
    # go to next day
    puts " next day"  if BMXSIM_OUTPUT > 0
    BugmTime.go_past_end_of_day
    # resolve contracts
    STDOUT.write "resolve contracts: 0 / 0" if BMXSIM_OUTPUT > 0
    counter = 0
    max_counter = Contract.pending_resolution.count
    Contract.pending_resolution.each do |contract|
      counter += 1
      STDOUT.write "\rresolve contracts: #{counter} / #{max_counter}" if BMXSIM_OUTPUT > 0
      ContractCmd::Resolve.new(contract).project
    end
    #signal end of day
    puts " DAY COMPLETE"  if BMXSIM_OUTPUT > 0
    STDOUT.flush
    # continue_story  # wait for key press
  end

  # Calling binding.pry to allow investigating the state of the simulation
  # Type "c" to continue and end the program
  binding.pry
  puts "--------------------------- simulation finished ---------------------------"
end
puts time
puts 'FINI' if false  # this line is only here for binding.pry to work
# FINI
