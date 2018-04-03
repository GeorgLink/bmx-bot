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
NUMBER_OF_WORKERS = 10
NUMBER_OF_FUNDERS = 1
NUMBER_OF_ISSUES = 10
FUNDER_STARTING_BALANCE = 100000000
WORKER_STARTING_BALANCE = 0
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
funders = []
workers = []
(1..NUMBER_OF_WORKERS).each do |worker_id|
  worker = FB.create(:user, email: "worker#{worker_id}@bugmark.net", balance: WORKER_STARTING_BALANCE).user
  workers.push(Bmxsim_Person.new(worker,repo))
end
(1..NUMBER_OF_FUNDERS).each do |funder_id|
  funder = FB.create(:user, email: "funder#{funder_id}@bugmark.net", balance: FUNDER_STARTING_BALANCE).user
  funders.push(Bmxsim_Person.new(funder,repo))
end

# loop for each day
(1..SIMULATION_DAYS).each do |day|
  print "#{day}: "
  workers.each do |worker|
    print "."
    issue = repo.open_issue
    args  = {
      user_uuid: funders[0].uuid,
      price: 1,
      volume: 100,
      stm_issue_uuid: issue.uuid,
      maturation: BugmTime.end_of_day
    }
    offer = FB.create(:offer_bu, args).offer
    counter = OfferCmd::CreateCounter.new(offer, {user_uuid: worker.uuid}).project.offer
    ContractCmd::Cross.new(offer, :expand).project
    ContractCmd::Cross.new(counter, :expand).project
    # IssueCmd::Sync.new({exid: issue.exid, stm_status: "closed"}).project
    issue.close
  end
  BugmTime.go_past_end_of_day
  Contract.open.each do |contract|
    ContractCmd::Resolve.new(contract).project
  end
  puts " |" ; STDOUT.flush
end


# FINI
