# encoding: utf-8

module Blur
  class Network
    class User
      attr_accessor :nick, :name, :host, :channel
      
      def initialize nick
        @nick = nick.sub /^[@|~|\+|%|&]/, ''
      end
      
      def synchronize sender
        @nick, @name, @host = sender.nickname, sender.username, sender.hostname
      end
      
      def inspect
        %{#<#{self.class.name} @nick=#{@nick.inspect} @channel=#{@channel.name.inspect}>}
      end
      
      def to_s
        @nick
      end
    end
  end
end