#!/usr/bin/env ruby

# (c) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

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
NUMBER_OF_WORKERS = 4
NUMBER_OF_FUNDERS = 4  # equals number of projects
NUMBER_OF_ISSUES = 10
FUNDER_STARTING_BALANCE = 100000000
WORKER_STARTING_BALANCE = 0
WORKER_SKILLS = [1]  # ability to randomly create workers with different skills
SIMULATION_DAYS = 14

# run in turbo mode
BMX_SAVE_EVENTS  = "FALSE"
BMX_SAVE_METRICS = "FALSE"

require 'io/console'
def continue_story
  print "press any key"
  STDIN.getch
  print "            \r" # extra space to overwrite in case next sentence is short
end

puts "----- BUGMARK BOT -------------------------------------------"
puts "START #{Time.now} | C-c to exit"
puts "Process Name: #{PROCNAME}"
puts "Loading Environment..."
STDOUT.flush

require File.expand_path("~/src/bugmark/config/environment")

# delete all host data and create admin user
BugmHost.reset
BugmTime.set_day_offset(-1 * SIMULATION_DAYS)

puts "Simulate #{SIMULATION_DAYS}, starting on #{BugmTime.now}"

# simulation classes
require_relative 'issuetracker'
require_relative 'person'

# create Issue Tracker
issue_tracker = Bmxsim_IssueTracker.new

# create funders and workers
funders = []
(1..NUMBER_OF_FUNDERS).to_a.each do |funder_id|
  STDOUT.write "\rcreate funders: #{funder_id} / #{NUMBER_OF_FUNDERS}"
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
puts ""
workers = []
(1..NUMBER_OF_WORKERS).to_a.each do |worker_id|
  STDOUT.write "\rcreate workers: #{worker_id} / #{NUMBER_OF_WORKERS}"
  worker = FB.create(:user, email: "worker#{worker_id}@bugmark.net", balance: WORKER_STARTING_BALANCE).user
  # skill = (1..3).to_a.sample
  skill = WORKER_SKILLS.sample
  workers.push(Bmxsim_Worker_Treatment_NoMetrics.new(worker, issue_tracker, skill, "w#{worker_id}"))
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
puts ""

# loop for each day
(1..SIMULATION_DAYS).to_a.each do |day|
  puts "Day #{day}: #{BugmTime.now}"
  # print "#{day}: "
  # call funders in a random order
  funders.shuffle.each do |funder|
    # print "f"
    funder.do_work
  end
  # call workers in a random order
  workers.shuffle.each do |worker|
    # print "w"
    worker.do_work
    puts "worker[#{worker.get_name}:#{worker.get_skill}](#{worker.get_balance}): #{worker.issue_status}"
  end
  # go to next day
  puts " next day"
  BugmTime.go_past_end_of_day
  # resolve contracts
  STDOUT.write "resolve contracts: 0 / 0"
  counter = 0
  max_counter = Contract.pending_resolution.count
  Contract.pending_resolution.each do |contract|
    counter += 1
    STDOUT.write "\rresolve contracts: #{counter} / #{max_counter}"
    ContractCmd::Resolve.new(contract).project
  end
  #signal end of day
  puts " DAY COMPLETE" ; STDOUT.flush
  # continue_story
end

puts "-- simulation finished --"
binding.pry
puts 'FINI'
# FINI
