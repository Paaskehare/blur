# encoding: utf-8

Script :google_search do
  include DSL

  requires "em-http-request", "~> 1.0"

  command :search, aliases: %w(g google) do |user, channel, args|
    channel.say "Searching for #{args.force_encoding 'UTF-8'} …"
  end
end