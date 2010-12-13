# encoding: utf-8

require 'yaml'
require 'socket'

Thread.abort_on_exception = true

Dir.glob("#{File.dirname __FILE__}/pulse/**/*.rb").each &method(:require)

module Pulse
  class ConnectionError < StandardError; end

  class << Version = [1,3]
    def to_s; join ?. end
  end

  def self.connect options, &block
    Client.new(options).tap do |client|
      client.instance_eval &block
    end.connect
  end
end
