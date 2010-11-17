# encoding: utf-8

module Pulse
  class Client
    module Handling

  protected 
      # End of MOTD
      def got_end_of_motd command
        emit :connection_ready, @connection
      end

      # The /NAMES list
      def got_353 command
        users = command[3].split.map &User.method(:new)
        @channels[command[2]] ||= Channel.new(command[2], self, users)
      end

      # The IRCd is checking whether or not we're still alive
      # PING :1285409133
      # PONG :1285409133
      def got_ping command
        transmit :PONG, command[0]
      end

      # Someone has changed their nickname
      # mk!mk@maero.dk NICK mk_
      def got_nick command
        each_user command.sender.nickname do |user|
          emit :rename, user, command[0]
          user.name = command[0]
        end
      end

      # Someone has sent a message, it can be both a private message and
      # a channel message
      # mk!mk@maero.dk PRIVMSG #maero :tp: kod
      def got_privmsg command
        channel, message = command.params
        user = @channels[channel].user command.sender.nickname
        user.synchronize command.sender
        emit :message, user, @channels[channel], message
      end


      # Someone has entered a channel.
      def got_join command
        if channel = @channels[command[0]]
          user = User.new command.sender.nickname
          user.channel = channel
          user.synchronize command.sender
          channel.users << user
          emit :user_joined, user, channel
        end
      end

      # Someone has left a channel.
      def got_part command
        if channel = @channels[command[0]]
          user = channel.user command.sender.nickname
          channel.users.delete user
          emit :user_left, user, channel
        end
      end

      alias_method :got_422, :got_end_of_motd
      alias_method :got_376, :got_end_of_motd
    end
  end
end
