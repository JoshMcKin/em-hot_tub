require "em/hot_tub/version"
require "hot_tub"
require "em-synchrony"
require "em/hot_tub/pool"
require "em/hot_tub/sessions"
require "em/hot_tub/reaper"
module EventMachine::HotTub
  @@logger = Logger.new(STDOUT)

  def self.logger
    @@logger
  end

  def self.logger=logger
    @@logger = logger
  end

  def self.new(opts={},&client_block)
    if opts[:sessions] == true
      opts[:with_pool] = true
      Sessions.new(opts,&client_block)
    else
      Pool.new(opts,&client_block)
    end
  end
end

HotTub::KnownClients::KNOWN_CLIENTS['EventMachine::HttpConnection'] = {
  :close => lambda { |clnt|
    if clnt.conn
      clnt.conn.close_connection
      clnt.instance_variable_set(:@deferred, true)
    end
  },
  :clean => lambda { |clnt|
    if clnt.conn && clnt.conn.error?
      clnt.conn.close_connection
      clnt.instance_variable_set(:@deferred, true)
    end
    clnt
  }
}
