# encoding: utf-8

module Blur
  class Script < Module
    attr_accessor :name, :author, :version, :path, :client
    
    def evaluated?; @evaluated end
    
    def initialize path
      @path = path
      @evaluated = false
      
      if evaluate and @evaluated
        cache.load if Cache.exists? @name
        
        __send__ :loaded if respond_to? :loaded
      end
    end
    
    def Script name, version = [1,0], author = nil, &block
      @name    = name
      @author  = author
      @version = version
      
      instance_eval &block
      
      true
    end
    
    def unload!
      cache.save if @cache
      __send__ :unloaded if respond_to? :unloaded

      @cache = nil
    end

    def script name
      @client.scripts.find { |script| script.name == name }
    end
    
    def cache
      @cache ||= Cache.new self
    end
    
    def inspect
      %{#<#{self.class.name} @name=#{@name.inspect} @version=#{@version.inspect} @author=#{@author.inspect}>}
    end
    
  private
  
    def evaluate
      module_eval File.read(@path), File.basename(@path), 0
      @evaluated = true
    rescue Exception => exception
      puts "#{File.basename(@path) ^ :bold}:#{exception.line.to_s ^ :bold}: #{"error:" ^ :red} #{exception.message ^ :bold}"
    end
  end
end
