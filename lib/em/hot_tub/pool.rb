module EventMachine::HotTub
  class Pool < HotTub::Pool
    def initialize(opts={},&new_client)
      super
      @mutex  = EM::Synchrony::Thread::Mutex.new
      @cond   = EM::Synchrony::Thread::ConditionVariable.new #StubConditionVariable.new
      @reaper = EM::HotTub::Reaper.spawn(self) unless opts[:no_reaper]
    end
  end
end
