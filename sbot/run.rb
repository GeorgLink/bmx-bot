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
NUMBER_OF_WORKERS = 48
NUMBER_OF_FUNDERS = 4
NUMBER_OF_ISSUES = 10
FUNDER_STARTING_BALANCE = 100000000
WORKER_STARTING_BALANCE = 100
SIMULATION_DAYS = 5

# run in turbo mode
BMX_SAVE_EVENTS  = "FALSE"
BMX_SAVE_METRICS = "FALSE"

puts "----- BUGMARK BOT -------------------------------------------"
puts "START #{Time.now} | C-c to exit"
puts "Process Name: #{PROCNAME}"
puts "Loading Environment..."
STDOUT.flush

require File.expand_path("~/src/bugmark/config/environment")

# delete all host data and create admin user
BugmHost.reset
BugmTime.set_day_offset(-1 * SIMULATION_DAYS)

# simulation classes
require_relative 'issuetracker'
require_relative 'person'

# create repository
bmx_repo = FB.create(:repo).repo
repo = Bmxsim_IssueTracker.new(bmx_repo)

# create funders and workers
puts "create funders"
funders = []
(1..NUMBER_OF_FUNDERS).to_a.each do |funder_id|
  funder = FB.create(:user, email: "funder#{funder_id}@bugmark.net", balance: FUNDER_STARTING_BALANCE).user
  case funder_id
  when 1
    funders.push(Bmxsim_Funder_InversePay.new(funder, repo))
  when 2
    funders.push(Bmxsim_Funder_CorrelatedPay.new(funder, repo))
  when 3
    funders.push(Bmxsim_Funder_FixedPay.new(funder, repo))
  else
    funders.push(Bmxsim_Funder_RandomPay.new(funder, repo))
  end
end
puts "create workers"
workers = []
(1..NUMBER_OF_WORKERS).to_a.each do |worker_id|
  worker = FB.create(:user, email: "worker#{worker_id}@bugmark.net", balance: WORKER_STARTING_BALANCE).user
  skill = (1..3).to_a.sample
  case worker_id
  when (1..12)
    workers.push(Bmxsim_Worker_Treatment_NoMetrics.new(worker, repo, skill))
  when (13..24)
    workers.push(Bmxsim_Worker_Treatment_HealthMetrics.new(worker, repo, skill))
  when (25..36)
    workers.push(Bmxsim_Worker_Treatment_MarketMetrics.new(worker, repo, skill))
  else
    workers.push(Bmxsim_Worker_Treatment_BothMetrics.new(worker, repo, skill))
  end
end

# loop for each day
(1..SIMULATION_DAYS).to_a.each do |day|
  print "#{day}: "
  # call funders in a random order
  funders.shuffle.each do |funder|
    print "f"
    funder.do_work
  end
  # call workers in a random order
  workers.shuffle.each do |worker|
    print "w"
    worker.do_work
  end
  # go to next day
  BugmTime.go_past_end_of_day
  # resolve contracts
  counter = 0
  Contract.open.each do |contract|
    counter += 1
    STDOUT.write "\r#{counter}"
    ContractCmd::Resolve.new(contract).project
  end
  #signal end of day
  puts " |" ; STDOUT.flush
end


# FINI
