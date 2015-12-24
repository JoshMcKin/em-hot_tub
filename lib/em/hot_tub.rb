require "em/hot_tub/version"
require "hot_tub"
require "em-synchrony"
require "em-synchrony/thread"
require "em/hot_tub/pool"
require "em/hot_tub/sessions"
require "em/hot_tub/reaper"

module EventMachine::HotTub
  GLOBAL_SESSIONS = EM::HotTub::Sessions.new(:name => "Global Sessions")

  def self.logger
    HotTub.logger
  end

  def self.logger=logger
    HotTub.logger = logger
    HotTub.set_log_trace
  end

  # Set to true for more detail logs
  def self.trace=trace
    HotTub.trace = trace
    HotTub.set_log_trace
  end

  def self.log_trace?
    HotTub.log_trace?
  end

  def self.sessions
    GLOBAL_SESSIONS
  end

  def self.jruby?
    (defined?(JRUBY_VERSION))
  end

  def self.rbx?
    (defined?(RUBY_ENGINE) and RUBY_ENGINE == 'rbx')
  end

  # Resets global sessions, useful in forked environments
  # Does not reset one-off pools or one-off sessions
  def self.reset!
    GLOBAL_SESSIONS.reset!
  end

  # Shuts down global sessions, useful in forked environments
  # Does not shutdown one-off pools or one-off sessions
  def self.shutdown!
    GLOBAL_SESSIONS.shutdown!
  end

  # Adds a new Pool to the global sessions
  def self.add(url,opts={}, &client_block)
    GLOBAL_SESSIONS.add(url, opts, &client_block)
  end

  def self.run(url ,&run_block)
    pool = GLOBAL_SESSIONS.fetch(url)
    pool.run(&run_block)
  end

  def self.new(opts={}, &client_block)
    EM::HotTub::Pool.new(opts,&client_block)
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
