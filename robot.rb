#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift File.dirname(__FILE__) + '/library'
require 'blur'

# Basic options, we're going to fill this with networks.
#
# @see Blur::Network.new
# @see Blur::Client.new
options = {
  networks: [{
    hostname: "uplink.io",
    nickname: "testing",
    channels: %w{#test}
  }]
}

# Start connecting to all our networks.
#
# @see Blur.connect
Blur.connect options do
  # …
end