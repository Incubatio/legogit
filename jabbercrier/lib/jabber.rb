require 'rubygems'
require 'xmpp4r-simple'

class Jabber_Crier  


    def initialize(config)
        @config=config
    end

    # connect jabber crier on an account
    def connect
        @sock = Jabber::Simple.new(@config[:jabber_id], @config[:password])
#      presence(@config[:presence], @config[:status], @config[:priority])
    end 

    def to(receiver)
        @config[:to] = receiver
        self
    end

    def send(receiver)
        @config[:receiver] = receiver
        self
    end

    # Send message(s) to target(s).
    # Array|String $targets
    # Array|String $messages
    def execute()
        if @config[:to].is_a?(Array)
            if @config[:receiver].is_a?(Array)
                @config[:to].each do |t| 
                    @config[:receiver].each do|r| 
                        @sock.deliver(t, r) 
                    end
                end
            else
                @to.each do |t| @sock.deliver(t, @config[:receiver]) 
                end 
            end
        else
            if @config[:receiver].is_a?(Array)
                @config[:receiver].each do |r|
                    @sock.deliver(@config[:to], r)
                end
            else
                @sock.deliver(@config[:to], @config[:receiver])
            end
        end
    end

    # Disconnect the bot.
    def disconnect
        if @sock.connected?
#    deliver(@config[:master], "#{@config[:name]} disconnecting...")
            @sock.disconnect
        end
    end

end
