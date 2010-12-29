# encoding: utf-8

module Pulse
  class Settings < Hash

    attr_accessor :nickname, :username, :realname, :hostname

    def initialize options = {}
      @options = options

      @nickname = options[:nickname] or raise ArgumentError, "No nickname given"
      @username = options[:username] || @nickname
      @realname = options[:realname] || @username

      @script_path = options[:path] || File.expand_path(File.dirname $0) + '/scripts'
    end

    def port; @options[:port] or secure ? 6697 : 6667 end
    def secure?; @options[:secure] == true end
    def password?; not @options[:password].nil? end

    def scripts
      Dir.glob "#@script_path/*.rb"
    end

    def method_missing name, *args; @options[name] end
  end
end
