module EventMachine::HotTub
  class EmCache < Hash
    def initialize
      @mutex = EM::Synchrony::Thread::Mutex.new
      super
    end

    def set_unless_present(key,val)
      @mutex.synchronize do
        return fetch(key) if key?(key)
        store(key,val)
        val
      end
    end
  end

  class Sessions < HotTub::Sessions
    def initialize(opts={},&new_client)
      super
      @sessions = EmCache.new
      @reaper = EM::HotTub::Reaper.spawn(self) unless opts[:no_reaper]
    end

    # Safely initializes of sessions
    # expects a url string or URI
    def session(url)
      key = to_key(url)
      return @sessions[key] if @sessions[key]
      if @with_pool
        @sessions.set_unless_present(key,EventMachine::HotTub::Pool.new(@pool_options) { @new_client.call(url) })
      else
        @sessions.set_unless_present(key,@new_client.call(url))
      end
      @sessions[key]
    end
    alias :sessions :session

    def run(url,&block)
      session = sessions(url)
      return session.run(&block) if session.is_a?(EventMachine::HotTub::Pool)
      block.call(sessions(url))
    end

  end
end
