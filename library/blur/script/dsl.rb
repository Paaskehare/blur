# encoding: utf-8

module Blur
  class Script < Module
    # The +DSL+ module is a module that gives the ability to turn a
    # script into a DSL-like framework.
    #
    # What it does is automatically test to see if a message starts with a
    # trigger, and then, if so, it sends the command-part of the message to
    # the script object itself.
    #
    # This way, the plugin-writer doesn't need to have repetetive code like
    # that in every script.
    #
    # @example
    #   Script :example do
    #     include Fantasy
    #
    #     command :test do |user, channel, message|
    #       channel.say "I hear you."
    #     end
    #   end
    #
    #   # And if a user were to send the message ".test my method", it would
    #   # trigger the test block with the following arguments
    #   #
    #   # user    => #<Blur::Network::User … >
    #   # channel => #<Blur::Network::Channel … >
    #   # message => ".test my method"
    module DSL
      # The prefix that turns it into a possible command.
      Trigger = "."

      # Extend +klass+ with self.
      def self.included klass
        klass.extend self
      end

      # Called when a script has been loaded, for use in modules extending
      # the script.
      def module_init
        @__trigger = Trigger
        @__commands ||= {}
      end

      # Add a gem dependency, with specific requirements.
      def requires name, *requirements
        dependency = Gem::Dependency.new name, *requirements

        if dependency.matching_specs.empty?
          dependency_missing dependency
        else
          # require dependency
          spec = dependency.to_spec
          spec.activate if spec
        end
      end

      # Set a new trigger prefix.
      def trigger trigger
        @__trigger = trigger
      end

      # Add a new command trigger.
      def command name, options = {}, &block
        @__commands ||= {}
        @__commands[name.to_s] = block

        if options[:aliases]
          options[:aliases].each do |cmd|
            @__commands[cmd.to_s] = block
          end
        end
      end
      
      # Handle all calls to the scripts +message+ method, check to see if
      # the message containts a valid command, serialize it and pass it to
      # the script as command_name with the parameters +user+, +channel+
      # and +message+.
      def message user, channel, line
        return unless line.start_with? @__trigger
        
        command, args = line.split $;, 2
        trigger = sanitize_command command

        if handler = @__commands[trigger]
          handler.(user, channel, args)
        end
      end
      
    protected

      # A needed dependency wasn't found.
      def dependency_missing dependency
        log.error "Dependency for script #{@__name} missing: #{dependency.name} (#{dependency.requirement})"
      end
      
      # Strip all non-word characters from the input command.
      def sanitize_command name
        name.gsub /\W/, '' if name
      end
    end
  end
end
