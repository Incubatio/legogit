#!/usr/local/bin/ruby

require "socket"


class IRC

    def initialize(sock=nil)
        to(sock)
    end

    def to(sock)
        @sock = sock
        self
    end

    def as(name)
        @nick = name
        self
    end
    
    def join(chan)
        @channel = chan
        self
    end

    def send(s)
        puts "==> #{s}"
        @sock.send "#{s}\n", 0 
    end

    def connect()
        # Connect to the IRC server
        send "USER poo poo pi :doo poo"
        send "NICK #{@nick}"
        send "JOIN #{@channel}"
    end

    def disconnect()
        quit()
        puts "disconnection complete"
        @sock.close
        @sock = nil
    end

    def quit(msg="")
         send "QUIT :#{msg}"
    end 

    def evaluate(s)
        # Make sure we have a valid expression (for security reasons), and
        # evaluate it if we do, otherwise return an error message
        if s =~ /^[-+*\/\d\s\eE.()]*$/ then
            begin
                s.untaint
                return eval(s).to_s
            rescue Exception => detail
                puts detail.message()
            end
        end
        return "Error"
    end

    def handle_server_input(s)
        # This isn't at all efficient, but it shows what we can do with Ruby
        # (Dave Thomas calls this construct "a multiway if on steroids")
        case s.strip
            when /^PING :(.+)$/i
                puts "[ Server ping ]"
                send "PONG :#{$1}"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
                puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001PING #{$4}\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
                puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:EVAL (.+)$/i
                puts "[ EVAL #{$5} from #{$1}!#{$2}@#{$3} ]"
                send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{evaluate($5)}"
            else
                puts s
        end
    end

    # Connect and handles inputs
    def main_loop()
        # Just keep on truckin' until we disconnect
        c, temp_code = nil
        while(line = @sock.gets)
            c = parse_command(line)
            if temp_code != c[1]
                puts
            end
            puts c[1]+": "+c[2].join('\n')
            ready = select([@sock, $stdin], nil, nil, nil)
            next if !ready
            for s in ready[0]
                if s == $stdin then
                    return if $stdin.eof
                    s = $stdin.gets
                    send s
                elsif s == @sock then
                    return if @sock.eof
                    s = @sock.gets
                    handle_server_input(s)
                end
            end
        end
    end

    # Wait for response code
    def wait_for(code)
        ok = false
        c, temp_code = nil
        while(line = @sock.gets)
            c = parse_command(line)
            if temp_code == c[1]
                cmd = ""
            else
                cmd = c[1] + " :\n"
                puts
            end
            puts cmd + c[2].join('\n')
            temp_code = c[1]
            next if (irc_code = c[1].to_i) == 0 
            next unless irc_code == code or dc_type(irc_code) == NumericType::Error
            ok = true if irc_code == code
            break
        end
        unless ok
            exit 1
        end
        puts
        puts
    end

    # Parse an irc returned line. 
    # Returns an array: [addr, cmd, args]
    #
    def parse_command(line)

        args = nil

        # Parse: [:addr] cmd args*
        return nil unless line =~ /^(?::([^ ]+) )?([^ ]+)(?: (.+))?$/

        # Parse arguments...
        addr, cmd, arg = $1, $2, $3
        if arg
          if arg[0] == ?:
            args = arg[1..-1].to_a
          else 
            if i = arg.index(' :')
              last = arg[(i+2)..-1]
              arg = arg[0...i]
            end  
            args = arg.split  ' '
            args << last if i 
          end  
        end  

        [addr, cmd, args]

    end 

    # Numeric command types.
    module NumericType
        Client      = 0
        Response    = 1
        Error       = 2
        Other       = 3
    end


    # Determines the type or category of 3-digit command.
    def dc_type(code)
        case code
            when 0...100:   NumericType::Client
            when 200...400: NumericType::Response
            when 400...600: NumericType::Error
            else            NumericType::Other
        end
    end
end
