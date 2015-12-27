require "em/hot_tub/reaper"
module EventMachine::HotTub

  class Pool < HotTub::Pool

    include EventMachine::HotTub::Reaper::Mixin

    def initialize(opts={},&client_block)
      super(opts, &client_block)
      @mutex = EM::Synchrony::Thread::Mutex.new
      @cond  = EM::Synchrony::Thread::ConditionVariable.new
      @kill_reaper = false
      EM.add_shutdown_hook {shutdown!} unless @sessions_key
    end
  end
end