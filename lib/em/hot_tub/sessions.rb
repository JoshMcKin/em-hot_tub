require "em/hot_tub/reaper"
module EventMachine::HotTub

  class Sessions < HotTub::Sessions
  	
    include EventMachine::HotTub::Reaper::Mixin

    def initialize(opts={})
      super opts
      @mutex = EM::Synchrony::Thread::Mutex.new
      @kill_reaper = false
    end
  end
end
