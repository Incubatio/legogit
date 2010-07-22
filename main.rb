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
require 'interface'
require 'IRC'

#TODO: when config will become bigger add a config file
$nick="legogit"
$channel="#legodata"

# Error message displayed if cmd don't respect the syntax
def usage
    puts
    puts "Legogit V#{$VERSION}"
    puts "Usage: ruby legogit.rb connect|msg|notify [<string>]"
    puts
    puts "Options available:"
    puts "   -- connect                    - connect bot on irc and wait plugin action(s)"
       #TODO (or not) implement functionalities/plugins on connect
    puts "   -- msg     <message>          - send a message to channel(s) or user(s)"
    puts "   -- notify  <notice>  <TITLE>  - send a notice to channel(s) or user(s)"
    exit 1
end

# Init socket and irc object
def init_irc
    sock = TCPSocket.open('irc.freenode.net', 6667)
    irc = IRC.new(sock)
    irc.as($nick).join($channel).connect()
    # We wait until the end of the complete initialization(channel joined and people listed).
    irc.wait_for(Rpl::NamesList)
    irc
end

# Get command and execute linked action
case ARGV[0]
when "connect"
    irc=init_irc
    begin
        irc.main_loop()
    rescue Interrupt
    rescue Exception => detail
        puts detail.message()
        print detail.backtrace.join("\n")
        retry
    end
when "msg"
    unless ARGV[1]
        usage
    end
    irc=init_irc
    ARGV[1].split("\n").each do |line|
        irc.send "PRIVMSG #{$channel} :" + line
    end
when "notify"
    unless ARGV[1] and ARGV[2]
        usage
    end
    irc=init_irc
    irc.send "NOTICE #{$channel} :------------------------ #{ARGV[2]} -----------------------------=>"
    sleep(0.5)
    ARGV[1].split("\n").each do |line|
        irc.send "NOTICE #{$channel} :-- % #{line}"
        sleep(0.5)
    end
    irc.send "NOTICE #{$channel} :<=-------------------)-(o" + "_" * ARGV[2].length + "O)-(---------------------------#"

else
    usage
end
irc.disconnect()
