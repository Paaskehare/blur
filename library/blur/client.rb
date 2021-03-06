# encoding: utf-8

require 'blur/handling'

module Blur
  # The +Client+ class is the controller of the low-level access.
  #
  # It stores networks, scripts and callbacks, and is also encharge of
  # distributing the incoming commands to the right networks and scripts.
  class Client
    include Handling, Logging
    
    # @return [Array] the options that is passed upon initialization.
    attr_accessor :options
    # @return [Array] a list of scripts that is loaded during runtime.
    attr_accessor :scripts
    # @return [Array] a list of instantiated networks.
    attr_accessor :networks
    
    # Instantiates the client, stores the options, instantiates the networks
    # and then loads available scripts.
    #
    # @param [Hash] options the options for the client.
    # @option options [Array] networks list of hashes that contain network
    #   options.
    def initialize options
      @options   = options
      @scripts   = []
      @networks  = []
      @callbacks = {}
      
      @networks = @options[:networks].map {|options| Network.new options }
      
      load_scripts
      trap 2, &method(:quit)

      EventMachine.threadpool_size = 1
    end
    
    # Connect to each network available that is not already connected, then
    # proceed to start the run-loop.
    def connect
      networks = @networks.select {|network| not network.connected? }
      
      EventMachine.run do
        networks.each do |network|
          network.delegate = self
          network.connect
        end

        EventMachine.error_handler{|e| p e }
      end
    end
    
    # Is called when a command have been received and parsed, this distributes
    # the command to the loader, which then further distributes it to events
    # and scripts.
    #
    # @param [Network] network the network that received the command.
    # @param [Network::Command] command the received command.
    def got_command network, command
      log "#{'←' ^ :green} #{command.name.to_s.ljust(8, ' ') ^ :light_gray} #{command.params.map(&:inspect).join ' '}"
      name = :"got_#{command.name.downcase}"
      
      if respond_to? name
        __send__ name, network, command
      end
    end
    
    # Searches for scripts in working_directory/scripts and then loads them.
    def load_scripts
      # Load script extensions.
      Script.load_extensions!

      # Load the scripts.
      script_path = File.dirname $0
      
      Dir.glob("#{script_path}/scripts/*.rb").each do |path|
        script = Script.new path
        script.__client = self
        
        @scripts << script
      end
    end
    
    # Unload all scripts gracefully that have been loaded into the client.
    #
    # @see Script#unload!
    def unload_scripts
      # Unload script extensions.
      Script.unload_extensions!

      @scripts.each do |script|
        script.unload!
      end.clear
    end

    # Called when a network connection is either closed, or terminated.
    def network_connection_closed network
      emit :connection_close, network
    end
    
    # Try to gracefully disconnect from each network, unload all scripts and
    # exit properly.
    #
    # @param [optional, Symbol] signal The signal received by the system, if any.
    def quit signal = :SIGINT
      @networks.each do |network|
        network.transmit :QUIT, "Got SIGINT?"
        network.disconnect
      end
      
      unload_scripts
      
      EventMachine.stop
    end
    
  private    
    # Finds all callbacks with name `name` and then calls them.
    # It also sends `name` to {Script} if the script responds to `name`, to all
    #   available scripts.
    #
    # @param [Symbol] name the corresponding event-handlers name.
    # @param [...] args Arguments that is passed to the event-handler.
    # @private
    def emit name, *args
      EM.defer do
        @callbacks[name].each do |callback|
          callback.call *args
        end if @callbacks[name]

        scripts = @scripts.select{|script| script.__emissions.include? name }
        
        scripts.each do |script|
          begin
            script.__send__ name, *args
          rescue Exception => exception
            log.error "#{File.basename(script.__path) << " - " << exception.message ^ :bold} on line #{exception.line.to_s ^ :bold}"
            puts exception.backtrace.join "\n"
          end
        end
      end
    end
    
    # Stores the block as an event-handler with name `name`.
    #
    # @param [Symbol] name the corresponding event-handlers name.
    # @param [Block] block the event-handlers block that serves as a trigger.
    # @private
    def catch name, &block
      (@callbacks[name] ||= []) << block
    end
    
  end
end
