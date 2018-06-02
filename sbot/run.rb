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
  setting["run_simulation_days"] = 15 unless setting.key?("run_simulation_days")
  RUN_SIMULATION_DAYS = setting["run_simulation_days"]  # simulation: 1780 days for 5 years

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
  setting["workers"] = {
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
  } unless setting.key?("workers")
  WORKERS = setting["workers"]
  setting["worker_starting_balance"] = 1000 unless setting.key?("worker_starting_balance")
  WORKER_STARTING_BALANCE = setting["worker_starting_balance"]  # simulation: 1000 enough to get started
  # option to randomly assign different skills to  workers
  setting["worker_skills"] = [1] unless setting.key?("worker_skills")
  WORKER_SKILLS = setting["worker_skills"]   # simulation: [1]

  # ==== funders ====
  # funder options:
  # - fixedPay
  # - randomPay
  # - inversePay
  # - correlatedpay
  # IDEA: projects may differ by difficulty probabilities
  setting["funders"] = [
    # simulation: always all four funders
    'randomPay',
    'fixedPay',
    'inversePay',
    'correlatedpay',
  ] unless setting.key?("funders")
  FUNDERS = setting["funders"]   # each funder represents a single project
  setting["funder_starting_balance"] = 100000000 unless setting.key?("funder_starting_balance")
  FUNDER_STARTING_BALANCE = setting["funder_starting_balance"]

  # ==== issues and contracts ====
  # #issue=#offer created
  # value is 0..maximum
  setting["number_of_issues_daily_per_funder"] = 2 unless setting.key?("number_of_issues_daily_per_funder")
  NUMBER_OF_ISSUES_DAILY_PER_FUNDER = setting["number_of_issues_daily_per_funder"]  # simulation: 15
  # PRICES and DIFFICULTIES need to have the same number of elements
  # PRICES are float values. The first value is fixed price bot's value
  setting["prices"] = [0.95, 0.90, 0.85, 0.80] unless setting.key?("prices")
  PRICES = setting["prices"]   # simulation: [0.95, 0.90, 0.85, 0.80]
  # the keys for DIFFICULTIES need to be integers
  setting["difficulties"] = { 1 => 30, 2 => 30, 3 => 30, 4 => 10} unless setting.key?("difficulties")
  DIFFICULTIES = setting["difficulties"]
  # simulation: { 1 => 30, 2 => 30, 3 => 30, 4 => 10}
  # 10% chance that issue can never be finished by skill-1 worker
  # equal chance for other three difficulties
  setting["maturation_days_in_future"] = 2 unless setting.key?("maturation_days_in_future")
  MATURATION_DAYS_IN_FUTURE = setting["maturation_days_in_future"]  # simulation: 2 (3 days of work)
  # end of:  0 = today, 1 = tomorrow


  # output
  setting["bmxsim_output"] = 1 unless setting.key?("bmxsim_output")
  BMXSIM_OUTPUT = setting["bmxsim_output"] || 1  # 0 no output, 1 slim output, 9 detailed output

  # run in turbo mode
  setting["bmx_save_events"] = "FALSE" unless setting.key?("bmx_save_events")
  BMX_SAVE_EVENTS  = setting["bmx_save_events"]
  setting["bmx_save_metrics"] = "FALSE" unless setting.key?("bmx_save_metrics")
  BMX_SAVE_METRICS = setting["bmx_save_metrics"]

  # CSV output file
  OUTPUT_PATH = 'simout/'
  setting['git_sha'] = `git rev-parse HEAD`.to_s.gsub(/\s/,'')
  GIT_SHA = setting['git_sha']
  setting['simulation_date'] = Time.now.to_s[0..18]
  SIMULATION_DATE = setting['simulation_date']
  if ARGV.empty?
    SETTINGS_FILE = "none"
    HEALTH_CSV = "#{OUTPUT_PATH}sim_#{setting['simulation_date'].gsub(/\s/,'_').gsub(/:/,'-')}_health.csv"
    BALANCE_CSV = "#{OUTPUT_PATH}sim_#{setting['simulation_date'].gsub(/\s/,'_').gsub(/:/,'-')}_balances.csv"
  else
    SETTINGS_FILE = ARGV[0].split('/').last.gsub(/\.yml/,'')
    HEALTH_CSV = "#{OUTPUT_PATH}health.csv"
    BALANCE_CSV = "#{OUTPUT_PATH}balances.csv"
  end
  SETTINGS_YAML = "#{OUTPUT_PATH}#{setting['simulation_date'].gsub(/\s/,'_').gsub(/:/,'-')}_#{SETTINGS_FILE}.yml"

# NOT NEEDED because we are saving the GIT_SHA
  File.open(SETTINGS_YAML, "w") do |file|
    file.write setting.to_yaml
  end
  # Save the parameters
  # out_file = File.new(CSV_FILE+".settings", "w")
  # out_file.puts("GIT SHA1 = #{GIT_SHA}")
  # out_file.puts("Time.now = #{Time.now}")
  # out_file.puts("Commandline arguments: #{ARGV}")
  # out_file.puts("RUN_SIMULATION_DAYS = #{RUN_SIMULATION_DAYS}")
  # out_file.puts("WORKERS = #{WORKERS}")
  # out_file.puts("WORKER_STARTING_BALANCE = #{WORKER_STARTING_BALANCE}")
  # out_file.puts("WORKER_SKILLS = #{WORKER_SKILLS}")
  # out_file.puts("FUNDERS = #{FUNDERS}")
  # out_file.puts("FUNDER_STARTING_BALANCE = #{FUNDER_STARTING_BALANCE}")
  # out_file.puts("NUMBER_OF_ISSUES_DAILY_PER_FUNDER = #{NUMBER_OF_ISSUES_DAILY_PER_FUNDER}")
  # out_file.puts("PRICES = #{PRICES}")
  # out_file.puts("DIFFICULTIES = #{DIFFICULTIES}")
  # out_file.puts("MATURATION_DAYS_IN_FUTURE = #{MATURATION_DAYS_IN_FUTURE}")
  # out_file.puts("")
  # out_file.puts("====== REMINDER: user balances are at end of file =======")  # empty line before health metrics are output
  # out_file.puts("")  # empty lines before health metrics are output
  # out_file.puts("")  # empty lines before health metrics are output
  # out_file.close

  # output health
  if (!File.exist?(HEALTH_CSV))
    health_a = []
    health_a.push("run")  # time and date of run
    health_a.push("settings")  # settingsfile
    health_a.push("git_sha")  # git sha allows tracing settings file
    health_a.push("day")  # day in simulation
    health_a.push("funder")  # funder type
    health_a.push("open_issues")
    health_a.push("closed_issues")
    health_a.push("resolution_efficiency")
    health_a.push("open_issue_age")
    health_a.push("closed_issue_resolution_duration")
    health_a.push("difficult_closed_issue_rate")
    health_a.push("norm_open_issues")
    health_a.push("norm_closed_issues")
    health_a.push("norm_resolution_efficiency")
    health_a.push("norm_open_issue_age")
    health_a.push("norm_closed_issue_resolution_duration")

    CSV.open(HEALTH_CSV, "wb") do |csv|
      csv << health_a
    end
  end

  # output user balances
  if (!File.exist?(BALANCE_CSV))
    CSV.open(BALANCE_CSV, "wb") do |csv|
      csv << ['run', 'settings', 'git_sha', 'day','email', 'type', 'balance', 'contract_earnings', 'contract_payout_frequency']
    end
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
  puts "Arguments: #{ARGV}"
  puts "Loading Environment..." if BMXSIM_OUTPUT > 0
  STDOUT.flush

  require File.expand_path("~/src/exchange/config/environment")
  # binding.pry

  # delete all host data and create admin user
  BugmHost.reset
  BugmTime.set_day_offset(-1 * RUN_SIMULATION_DAYS)

  puts "Simulate #{RUN_SIMULATION_DAYS} days, starting on #{BugmTime.now}"

  # simulation classes
  require_relative 'issuetracker'
  require_relative 'person'

  # create Issue Tracker
  issue_tracker = Bmxsim_IssueTracker.new

  # lookup for csv output
  project_funder = {}
  email_worker = {}

  # CREATE RUNDERS ------------------------------------------------------------
  funders = []
  # FUNDERS options:
  # - fixedPay
  # - randomPay
  # - inversePay
  # - correlatedpay
  project = 0
  (FUNDERS).to_a.each do |funder_type|
    project += 1
    STDOUT.write "\rcreate funders: #{project.to_s.rjust(Math.log10(FUNDERS.length).to_i+1)}/#{FUNDERS.length}"  if BMXSIM_OUTPUT > 0
    funder = FB.create(:user, email: "funder#{project}_#{funder_type}@bugmark.net", balance: FUNDER_STARTING_BALANCE).user
    email_worker.merge!({funder[:email] => funder_type})
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
    project_funder.merge!({funders.last.project_uuid => funder_type})
  end
  puts "" if BMXSIM_OUTPUT > 0

  # CREATE WORKERS ------------------------------------------------------------
  workers = []
  number_of_workers = 0
  WORKERS.to_a.each {|v| number_of_workers += v[1]}
  worker_id = 0
  WORKERS.each do |worker_type, worker_number|
    worker_number.times do
      worker_id += 1
      STDOUT.write "\rcreate workers: #{worker_id.to_s.rjust(Math.log10(number_of_workers).to_i+1)}/#{number_of_workers}" if BMXSIM_OUTPUT > 0
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

  # loop for each day ----------------------------------------------------------
  (1..RUN_SIMULATION_DAYS).to_a.each do |day|
    puts "Day #{day.to_s.rjust(Math.log10(RUN_SIMULATION_DAYS).to_i+1)}/#{RUN_SIMULATION_DAYS} --- #{BugmTime.now}"  if BMXSIM_OUTPUT > 0
    $sim_day = day

    counter = 0
    # prepare output
    out_funder = "#{counter.to_s.rjust(Math.log10(funders.length).to_i+1)}/#{funders.length} funders"
    out_worker = "#{counter.to_s.rjust(Math.log10(workers.length).to_i+1)}/#{workers.length} workers"
    out_contract = "0/0 contracts resolved"
    STDOUT.write "simulate: #{out_funder} | #{out_worker} | #{out_contract}"

    # call funders in a random order
    counter = 0
    funders.shuffle.each do |funder|
      if BMXSIM_OUTPUT < 9
        counter += 1
        out_funder = "#{counter.to_s.rjust(Math.log10(funders.length).to_i+1)}/#{funders.length} funders"
        STDOUT.write "\rsimulate: #{out_funder} | #{out_worker} | #{out_contract}"
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
        out_worker = "#{counter.to_s.rjust(Math.log10(workers.length).to_i+1)}/#{workers.length} workers"
        STDOUT.write "\rsimulate: #{out_funder} | #{out_worker} | #{out_contract}"
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
        out_contract = "#{counter.to_s.rjust(Math.log10(max_counter).to_i+1)}/#{max_counter} contracts resolved"
        STDOUT.write "\rsimulate: #{out_funder} | #{out_worker} | #{out_contract}"
        # STDOUT.write "\rresolve contracts: #{counter} / #{max_counter}" if BMXSIM_OUTPUT > 0
      end
      ContractCmd::Resolve.new(contract).project
    end

    # Write project health data to a CSV file
    health_h = issue_tracker.get_project_health_all_projects
    health_h.to_a.each do |val|
      if val[1].is_a?(Hash) then  # this is a project
        health_a = []
        health_a.push(SIMULATION_DATE)  # run
        health_a.push(SETTINGS_FILE)  # settings
        health_a.push(GIT_SHA)  # settings
        health_a.push($sim_day)  # simulation day
        health_a.push(project_funder[val[0]])  # funder type
        # health_a.push(val[0])  # uuid of project
        health_a.push(val[1][:open_issues])
        health_a.push(val[1][:closed_issues])
        health_a.push(val[1][:resolution_efficiency])
        health_a.push(val[1][:open_issue_age])
        health_a.push(val[1][:closed_issue_resolution_duration])
        health_a.push(val[1][:difficult_closed_issue_rate])
        health_a.push(val[1][:norm_open_issues])
        health_a.push(val[1][:norm_closed_issues])
        health_a.push(val[1][:norm_resolution_efficiency])
        health_a.push(val[1][:norm_open_issue_age])
        health_a.push(val[1][:norm_closed_issue_resolution_duration])
        CSV.open(HEALTH_CSV, "ab") do |csv|
          csv << health_a
        end
      else
        # health_a.push(val[1])
      end
    end

    # output user balances
    CSV.open(BALANCE_CSV, "ab") do |csv|
      # ---- EARNINGS FROM CONTRACTS
      sql = "SELECT positions.user_uuid, SUM(positions.volume - positions.value) as earned
      FROM positions
      JOIN amendments ON amendments.uuid = positions.amendment_uuid
      JOIN contracts ON contracts.uuid = amendments.contract_uuid
      WHERE contracts.status = 'resolved'
        AND contracts.awarded_to = positions.side
      GROUP BY positions.user_uuid
      "
      earnings = ActiveRecord::Base.connection.execute(sql).to_a

      # ----  CONTRACTS WITH EARNINGS
      sql = "SELECT positions.user_uuid, COUNT(DISTINCT contracts.uuid) as contrs
      FROM positions
      JOIN amendments ON amendments.uuid = positions.amendment_uuid
      JOIN contracts ON contracts.uuid = amendments.contract_uuid
      WHERE contracts.status = 'resolved'
        AND contracts.awarded_to = positions.side
      GROUP BY positions.user_uuid
      "
      contract_payout_array = ActiveRecord::Base.connection.execute(sql).to_a


      # ----  NUMBER OF CONTRACTS
      sql = "SELECT positions.user_uuid, COUNT(DISTINCT contracts.uuid) as contrs
      FROM positions
      JOIN amendments ON amendments.uuid = positions.amendment_uuid
      JOIN contracts ON contracts.uuid = amendments.contract_uuid
      WHERE contracts.status = 'resolved'
      GROUP BY positions.user_uuid
      "
      contract_all_array = ActiveRecord::Base.connection.execute(sql).to_a

      User.all.each do |u|
        earning = earnings.select { |i| i['user_uuid'] == u[:uuid] }
        earning = [{'earned' => 0.0}] unless earning.length>0
        earning = earning['earned'].to_f
        good_contracts = contract_payout_array.select { |i| i['user_uuid'] == u[1] }
        good_contracts = [{'contrs' => 0.0}] unless good_contracts.length>0
        good_contracts = good_contracts['contrs'].to_f
        all_contracts = records_array.select { |i| i['user_uuid'] == u[1] }
        all_contracts = [{'contrs' => 0.0}] unless all_contracts.length>0
        all_contracts = all_contracts['contrs'].to_f
        contract_payout_frequency = good_contracts / all_contracts
        user = [SIMULATION_DATE, SETTINGS_FILE, GIT_SHA, $sim_day, u[:email], email_worker[u[:email]], u[:balance], earning, contract_payout_frequency]
        csv << user
      end
    end

    # signal end of day
    puts ""  if BMXSIM_OUTPUT > 0
    STDOUT.flush
    # continue_story  # wait for key press
  end

  setting['finished'] = "SIMULATION FINISHED WITHOUT ERROR"
  File.open(SETTINGS_YAML, "w") do |file|
    file.write setting.to_yaml
  end
  # Calling binding.pry to allow investigating the state of the simulation
  # Type "c" to continue and end the program
  # binding.pry unless ARGV[1]=="doNotWait"
  puts "--------------------------- simulation finished ---------------------------"
end
puts time
puts 'FINI' if false  # this line is only here for binding.pry to work
# FINI
