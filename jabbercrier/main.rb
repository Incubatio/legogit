#!/usr/bin/env ruby

#
# Legogit 
#
#   - Execute action as a script
#   - Can be use as a bot (thx to the plugin system not yet developped)
#

$VERSION = "0.1"
#require 'rubygems'

$: << File.join(File.dirname(__FILE__), "lib")
require 'jabber.rb'

config = {
    :jabber_id  => 'jabberbot@neko.im', 
    :password   => 'time2bot',
    :nick       => 'JabberCrier',
    :to         => 'incubatio@gmail.com'
}

# Error message displayed if cmd don't respect the syntax
def usage
    puts
    puts "Legogit V#{$VERSION}"
    puts "Usage: ruby legogit.rb msg|notify [<string>]"
    puts
    puts "Options available:"
       #TODO (or not) implement functionalities/plugins on connect
    puts "   -- msg     <message>          - send a message to channel(s) or user(s)"
    puts "   -- notify  <notice>  <TITLE>  - send a notice to channel(s) or user(s)"
    exit 1
end


# Get command and execute linked action
case ARGV[0]
when "msg"
    unless ARGV[1]
        usage
    end
    msg = ARGV[1]
when "notify"
    unless ARGV[1] and ARGV[2]
        usage
    end
    contents  = []
    contents +=  ["% ---------------------------- #{ARGV[2]} ----------------------------=>"]
    contents += ARGV[1].split("\n")

    msg  = contents.join("\n% -- ")
    msg += "\n% --------------------------)-(o" + "_" * ARGV[2].length + "O)-(-------------------------<="

else
    usage
end

crier = Jabber_Crier.new(config)
crier.connect
sleep 1
crier.send(msg).to(config[:to]).execute
sleep 3
crier.disconnect
