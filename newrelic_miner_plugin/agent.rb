module NewrelicMinerPlugin
  class Agent < NewRelic::Plugin::Agent::Base
    agent_config_options :name, :hostname, :port
    agent_guid 'newrelic_miner_plugin'
    agent_version '0.0.1'
    agent_human_labels('Miner') { name || hostname }

    def poll_cycle
      client = CGMiner::API::Client.new(hostname, port || 4028)

      summary = client.summary.body.first
      report_metric 'Summary/MH/5s', 'MH/second', summary['MHS 5s']
      report_metric 'Summary/MH/Average', 'MH/second', summary['MHS av']

      report_metric 'Summary/Shares/Accepted', 'shares', summary['Accepted']
      report_metric 'Summary/Shares/Rejected', 'shares', summary['Rejected']
      report_metric 'Summary/Shares/Discarded', 'shares', summary['Discarded']
      report_metric 'Summary/Shares/Stale', 'shares', summary['Stale']
      report_metric 'Summary/Shares/WU', 'MH/second', summary['Work Utility']

      report_metric 'Summary/Pool/RejectRate', 'Percent', summary['Pool Rejected%']

      client.devs.body.each do |device|
        device_name = "GPU#{ device['GPU'] }"

        report_metric "Devices/#{ device_name }/Temperature", 'Degrees Celsius', device['Temperature']
        report_metric "Devices/#{ device_name }/Fan/Speed", 'RPM', device['Fan Speed']
        report_metric "Devices/#{ device_name }/Fan/Percent", 'Percent', device['Fan Percent']
        report_metric "Devices/#{ device_name }/GPUActivity", 'Percent', device['GPU Activity']
        report_metric "Devices/#{ device_name }/MH/5s", 'MH/second', device['MHS 5s']
        report_metric "Devices/#{ device_name }/MH/Average", 'MH/second', device['MHS av']

        report_metric "Devices/#{ device_name }/HardwareErrors", 'Percent', device['Device Hardware%']
        report_metric "Devices/#{ device_name }/Rejected", 'Percent', device['Device Rejected%']
      end
    rescue Exception => e
      $stderr.puts "Exception: #{ e }"
      e.backtrace.to_a.each { |backtrace_line| $stderr.puts backtrace_line }
      raise e
    end
  end

  NewRelic::Plugin::Setup.install_agent :miner, self
end
