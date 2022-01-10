#!/bin/ruby
# frozen_string_literal: true

require 'logger'
require 'net/http'
require 'openssl'
require 'uri'
require 'yaml'


STDOUT.sync = true
@logger = Logger.new(STDOUT)

def verify_env_vars
  %w[CONFIGFILES_PATH API_HOST API_PORT BASIC_AUTH_USERNAME BASIC_AUTH_PASSWORD]
    .each { |var| raise "env var '#{var}' is empty or not provided" if ENV[var].to_s.empty? }
end

def retriable_http_request(config, retries = 3)
  http_request(config)
rescue StandardError => e
  @logger.info "Got error in http request attempt: #{e}"

  if retries > 0
    @logger.info "Going to retry request, attempt left #{retries}"
    sleep 3
    retriable_http_request(config, retries - 1)
  else
    raise 'Exhausted retry attempts'
  end
end

def http_request(config)
  uri = "#{ENV['API_HOST']}:#{ENV['API_PORT']}#{config['path']}"
  parsed_uri = URI.parse(uri)

  req_options = {
    open_timeout: config['client_conf']['request_timeout'],
    read_timeout: config['client_conf']['request_timeout'],
    ssl_timeout: config['client_conf']['request_timeout'],
    use_ssl: parsed_uri.scheme == 'https',
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
    max_retries: config['client_conf']['retry_attempts']
  }

  Net::HTTP.start(parsed_uri.hostname, parsed_uri.port, req_options) do |http|
    request = Net::HTTP::Put.new(parsed_uri)
    request['Content-Type'] = 'application/json'
    request.basic_auth(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])

    http.request(request, config['payload'])
  end
end

def config_files
  configfiles_path = ENV['CONFIGFILES_PATH']
  Dir["#{configfiles_path}/*"].sort
end

def execute_api_requests
    config_files
      .lazy
      .map { |configfile_path| YAML.load_file(configfile_path) }
      .flat_map { |config| config['api_calls'].map { |api_call| api_call.merge(config.except('api_calls')) } }
      .each_with_index.map { |config, index| @logger.info "[#{index}] Performing API request to #{config['path']}" ; config }
      .map { |config| retriable_http_request(config) }
      .map { |r| @logger.info "Response status code: #{r.code}. Response body: #{r.body}\n\n"; r }
      .select { |r| r.code.to_i > 200 }
      .count
end

@logger.info "===== API configurator starting ====="

verify_env_vars
http_errors = execute_api_requests
@logger.info "Total errors number #{http_errors}"

@logger.info "===== API configurator completed ====="

exit(http_errors)
