#!/usr/bin/env ruby

# (c) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

require 'benchmark'
require 'csv'
require 'yaml'

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

  # read settings file, if provided
  # IF ARGV[0] is a file, then
  # read YAML file
  setting = {}
  setting = YAML.load_file(ARGV[0]) unless ARGV.empty?
  # populate the simulation parameters from file or use defaults.

  # SIMULATION PARAMETERS
  RUN_SIMULATION_DAYS = setting["run_simulation_days"] || 15  # simulation: 1780 days for 5 years

  # ==== workers ====
  # worker options (provide number of each in hash)
  # - Random
  # - NoMetricsNoPrices_riskAverse
  # - NoMetricsNoPrices_random
  # - NoMetricsWithPrices_riskAverse
  # - NoMetricsWithPrices_rewardSeeking
  # - HealthMetricsNoPrices
  # - HealthMetricsWithPrices
  # Options not yet functional:
  # - MarketMetrics
  # - BothMetrics
  # - NoPricesNoMetrics_FullTaskInfoNoTimeLimit
  # - NoPricesNoMetrics_FullTaskInfoWithTimeLimit
  WORKERS = setting["workers"] || {
    # simulation: 170 workers for abundend workers scenario
    # simulation: 75 workers for scarce workers scenario
    # 'Random' => 10,
    'NoMetricsNoPrices_riskAverse' => 2,
    'NoMetricsNoPrices_random' => 2,
    'NoMetricsWithPrices_riskAverse' => 2,
    'NoMetricsWithPrices_rewardSeeking' => 2,
    'HealthMetricsNoPrices' => 2,
    'HealthMetricsWithPrices' => 2,
    # not yet functional:
    # 'MarketMetrics' => 0,
    # 'BothMetrics' => 0,
    # 'NoPricesNoMetrics_FullTaskInfoNoTimeLimit' => 0,
    # 'NoPricesNoMetrics_FullTaskInfoWithTimeLimit' => 0,
  }
  WORKER_STARTING_BALANCE = setting["worker_starting_balance"] || 1000  # simulation: 1000 enough to get started
  # option to randomly assign different skills to  workers
  WORKER_SKILLS = setting["worker_skills"] || [1]  # simulation: [1]

  # ==== funders ====
  # funder options:
  # - fixedPay
  # - randomPay
  # - inversePay
  # - correlatedpay
  # IDEA: projects may differ by difficulty probabilities
  FUNDERS = setting["funders"] || [
    # simulation: always all four funders
    'randomPay',
    'fixedPay',
    'inversePay',
    'correlatedpay',
  ]  # each funder represents a single project
  FUNDER_STARTING_BALANCE = setting["funder_starting_balance"] || 100000000

  # ==== issues and contracts ====
  # #issue=#offer created
  # value is 0..maximum
  NUMBER_OF_ISSUES_DAILY_PER_FUNDER = setting["number_of_issues_daily_per_funder"] || 2  # simulation: 15
  # PRICES and DIFFICULTIES need to have the same number of elements
  # PRICES are float values. The first value is fixed price bot's value
  PRICES = setting["prices"] || [0.95, 0.90, 0.85, 0.80]  # simulation: [0.95, 0.90, 0.85, 0.80]
  # the keys for DIFFICULTIES need to be integers
  DIFFICULTIES = setting["difficulties"] || { 1 => 30, 2 => 30, 3 => 30, 4 => 10}
  # simulation: { 1 => 30, 2 => 30, 3 => 30, 4 => 10}
  # 10% chance that issue can never be finished by skill-1 worker
  # equal chance for other three difficulties
  MATURATION_DAYS_IN_FUTURE = setting["maturation_days_in_future"] || 2  # simulation: 2 (3 days of work)
  # end of:  0 = today, 1 = tomorrow


  # output
  BMXSIM_OUTPUT = setting["bmxsim_output"] || 1  # 0 no output, 1 slim output, 9 detailed output

  # run in turbo mode
  BMX_SAVE_EVENTS  = setting["bmx_save_events"] || "FALSE"
  BMX_SAVE_METRICS = setting["bmx_save_metrics"] || "FALSE"

  # CSV output file
  if ARGV.empty?
    CSV_FILE = 'simout/sim_' + Time.now.to_s[0..18].gsub(/\s/,'_').gsub(/:/,'-')
  else
    CSV_FILE = 'simout/sim_' + ARGV[0].split('/').last.gsub(/\.yml/,'')
  end
  out_file = File.new(CSV_FILE+".settings", "w")
  # Save the parameters
  out_file.puts("GIT SHA1 = #{`git rev-parse HEAD`}")
  out_file.puts("Time.now = #{Time.now}")
  out_file.puts("Commandline arguments: #{ARGV}")
  out_file.puts("RUN_SIMULATION_DAYS = #{RUN_SIMULATION_DAYS}")
  out_file.puts("WORKERS = #{WORKERS}")
  out_file.puts("WORKER_STARTING_BALANCE = #{WORKER_STARTING_BALANCE}")
  out_file.puts("WORKER_SKILLS = #{WORKER_SKILLS}")
  out_file.puts("FUNDERS = #{FUNDERS}")
  out_file.puts("FUNDER_STARTING_BALANCE = #{FUNDER_STARTING_BALANCE}")
  out_file.puts("NUMBER_OF_ISSUES_DAILY_PER_FUNDER = #{NUMBER_OF_ISSUES_DAILY_PER_FUNDER}")
  out_file.puts("PRICES = #{PRICES}")
  out_file.puts("DIFFICULTIES = #{DIFFICULTIES}")
  out_file.puts("MATURATION_DAYS_IN_FUTURE = #{MATURATION_DAYS_IN_FUTURE}")
  out_file.puts("")
  out_file.puts("====== REMINDER: user balances are at end of file =======")  # empty line before health metrics are output
  out_file.puts("")  # empty lines before health metrics are output
  out_file.puts("")  # empty lines before health metrics are output
  out_file.close
  health_a = ["day"]
  health_a.push("funder")  # uuid of project
  # health_a.push("uuid")  # uuid of project
  health_a.push("open_issues")
  health_a.push("closed_issues")
  health_a.push("resolution_efficiency")
  health_a.push("open_issue_age")
  health_a.push("closed_issue_resolution_duration")
  health_a.push("norm_open_issues")
  health_a.push("norm_closed_issues")
  health_a.push("norm_resolution_efficiency")
  health_a.push("norm_open_issue_age")
  health_a.push("norm_closed_issue_resolution_duration")

  CSV.open(CSV_FILE+'_health.csv', "wb") do |csv|
    csv << health_a
  end

  # output user balances
  CSV.open(CSV_FILE+'_balances.csv', "wb") do |csv|
    csv << ['day','email', 'type', 'balance']
  end

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

  require File.expand_path("~/src/exchange/config/environment")
  # binding.pry

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
  uuid_funders = {}
  # FUNDERS options:
  # - fixedPay
  # - randomPay
  # - inversePay
  # - correlatedpay
  project = 0
  (FUNDERS).to_a.each do |funder_type|
    project += 1
    STDOUT.write "\rcreate funders: #{project} / #{FUNDERS.length}"  if BMXSIM_OUTPUT > 0
    funder = FB.create(:user, email: "funder#{project}_#{funder_type}@bugmark.net", balance: FUNDER_STARTING_BALANCE).user
    uuid_funders.merge!({funder.uuid => funder_type})
    case funder_type
    when 'fixedPay'
      funders.push(Bmxsim_Funder_FixedPay.new(funder, issue_tracker, project))
    when 'randomPay'
      funders.push(Bmxsim_Funder_RandomPay.new(funder, issue_tracker, project))
    when 'inversePay'
      funders.push(Bmxsim_Funder_InversePay.new(funder, issue_tracker, project))
    when 'correlatedpay'
      funders.push(Bmxsim_Funder_CorrelatedPay.new(funder, issue_tracker, project))
    else
      puts 'ERROR: unknown funder'
      raise "ERROR: unknown funder"
    end
  end
  puts "" if BMXSIM_OUTPUT > 0
  workers = []
  email_worker = {}
  number_of_workers = 0
  WORKERS.to_a.each {|v| number_of_workers += v[1]}
  worker_id = 0
  WORKERS.each do |worker_type, worker_number|
    worker_number.times do
      worker_id += 1
      STDOUT.write "\rcreate workers: #{worker_id} / #{number_of_workers}" if BMXSIM_OUTPUT > 0
      worker = FB.create(:user, email: "worker#{worker_id}_#{worker_type}@bugmark.net", balance: WORKER_STARTING_BALANCE).user
      email_worker.merge!({worker[:email] => worker_type})
      skill = WORKER_SKILLS.sample
      case worker_type
      when 'Random'
        workers.push(Bmxsim_Worker_Treatment_Random.new(worker, issue_tracker, skill, "w#{worker_id}"))
      when 'NoMetricsNoPrices_riskAverse'
        workers.push(Bmxsim_Worker_Treatment_NoMetricsNoPrices_riskAverse.new(worker, issue_tracker, skill, "w#{worker_id}"))
      when 'NoMetricsNoPrices_random'
        workers.push(Bmxsim_Worker_Treatment_NoMetricsNoPrices_random.new(worker, issue_tracker, skill, "w#{worker_id}"))
      when 'NoMetricsWithPrices_riskAverse'
        workers.push(Bmxsim_Worker_Treatment_NoMetricsWithPrices_riskAverse.new(worker, issue_tracker, skill, "w#{worker_id}"))
      when 'NoMetricsWithPrices_rewardSeeking'
        workers.push(Bmxsim_Worker_Treatment_NoMetricsWithPrices_rewardSeeking.new(worker, issue_tracker, skill, "w#{worker_id}"))
      when 'HealthMetricsNoPrices'
        workers.push(Bmxsim_Worker_Treatment_HealthMetricsNoPrices.new(worker, issue_tracker, skill, "w#{worker_id}"))
      when 'HealthMetricsWithPrices'
        workers.push(Bmxsim_Worker_Treatment_HealthMetricsWithPrices.new(worker, issue_tracker, skill, "w#{worker_id}"))
      # Not working yet:
      # when 'MarketMetrics'
      #   workers.push(Bmxsim_Worker_Treatment_MarketMetrics.new(worker, issue_tracker, skill, "w#{worker_id}"))
      # when 'BothMetrics'
      #   workers.push(Bmxsim_Worker_Treatment_BothMetrics.new(worker, issue_tracker, skill, "w#{worker_id}"))
      # when 'NoPricesNoMetrics_FullTaskInfoNoTimeLimit'
      #   workers.push(Bmxsim_Worker_Treatment_NoPricesNoMetrics_FullTaskInfoNoTimeLimit.new(worker, issue_tracker, skill, "w#{worker_id}"))
      # when 'NoPricesNoMetrics_FullTaskInfoWithTimeLimit'
      #   workers.push(Bmxsim_Worker_Treatment_NoPricesNoMetrics_FullTaskInfoWithTimeLimit.new(worker, issue_tracker, skill, "w#{worker_id}"))
      else
        puts 'ERROR: unknown worker'
        raise "ERROR: unknown worker"
      end
    end
  end
  puts "" if BMXSIM_OUTPUT > 0

  # loop for each day
  (1..RUN_SIMULATION_DAYS).to_a.each do |day|
    puts "Day #{day} / #{RUN_SIMULATION_DAYS} : #{BugmTime.now}"  if BMXSIM_OUTPUT > 0
    $sim_day = day

    # prepare output
    out_funder = "0 / #{funders.length} funders"
    out_worker = "0 / #{workers.length} workers"
    out_contract = "0 / 0 contracts resolved"
    STDOUT.write "simulating: #{out_funder} | #{out_worker} | #{out_contract}"

    # call funders in a random order
    counter = 0
    funders.shuffle.each do |funder|
      if BMXSIM_OUTPUT < 9
        counter += 1
        out_funder = "#{counter} / #{funders.length} funders"
        STDOUT.write "\rsimulating: #{out_funder} | #{out_worker} | #{out_contract}"
        # print "f" if BMXSIM_OUTPUT > 0 && BMXSIM_OUTPUT < 9
      end
      funder.do_work
      puts "funder[#{funder.get_name}](#{funder.get_balance})"  if BMXSIM_OUTPUT > 8
    end
    # call workers in a random order

    counter = 0
    workers.shuffle.each do |worker|
      if BMXSIM_OUTPUT < 9
        counter += 1
        out_worker = "#{counter} / #{workers.length} workers"
        STDOUT.write "\rsimulating: #{out_funder} | #{out_worker} | #{out_contract}"
        # print "w"  if BMXSIM_OUTPUT > 0 && BMXSIM_OUTPUT < 9
      end
      worker.do_work
      puts "worker[#{worker.get_name}:#{worker.get_skill}](#{worker.get_balance}): #{worker.issue_status}" if BMXSIM_OUTPUT > 8
    end
    # go to next day
    # puts " next day"  if BMXSIM_OUTPUT > 0
    BugmTime.go_past_end_of_day
    # resolve contracts
    # STDOUT.write "resolve contracts: 0 / 0" if BMXSIM_OUTPUT > 0
    counter = 0
    max_counter = Contract.pending_resolution.count
    Contract.pending_resolution.each do |contract|
      if BMXSIM_OUTPUT < 9
        counter += 1
        out_contract = "#{counter} / #{max_counter} contracts resolved"
        STDOUT.write "\rsimulating: #{out_funder} | #{out_worker} | #{out_contract}"
        # STDOUT.write "\rresolve contracts: #{counter} / #{max_counter}" if BMXSIM_OUTPUT > 0
      end
      ContractCmd::Resolve.new(contract).project
    end

    # Write project health data to a
    health_h = issue_tracker.get_project_health_all_projects
    health_h.to_a.each do |val|
      if val[1].is_a?(Hash) then  # this is a project
        health_a = [$sim_day]
        health_a.push(uuid_funders.key(val[0]))  # funder
        # health_a.push(val[0])  # uuid of project
        health_a.push(val[1][:open_issues])
        health_a.push(val[1][:closed_issues])
        health_a.push(val[1][:resolution_efficiency])
        health_a.push(val[1][:open_issue_age])
        health_a.push(val[1][:closed_issue_resolution_duration])
        health_a.push(val[1][:norm_open_issues])
        health_a.push(val[1][:norm_closed_issues])
        health_a.push(val[1][:norm_resolution_efficiency])
        health_a.push(val[1][:norm_open_issue_age])
        health_a.push(val[1][:norm_closed_issue_resolution_duration])
        CSV.open(CSV_FILE+'_health.csv', "ab") do |csv|
          csv << health_a
        end
      else
        # health_a.push(val[1])
      end
    end

    # output user balances
    CSV.open(CSV_FILE+'_balances.csv', "ab") do |csv|
      User.all.each do |u|
        user = [$sim_day, u[:email], email_worker[u[:email]], u[:balance]]
        csv << user
      end
    end

    #signal end of day
    puts " DAY COMPLETE"  if BMXSIM_OUTPUT > 0
    STDOUT.flush
    # continue_story  # wait for key press
  end

  # IDEA: inform me that simulation is finished via email or other notification

  # Calling binding.pry to allow investigating the state of the simulation
  # Type "c" to continue and end the program
  binding.pry unless ARGV[1]=="doNotWait"
  puts "--------------------------- simulation finished ---------------------------"
end
puts time
puts 'FINI' if false  # this line is only here for binding.pry to work
# FINI
