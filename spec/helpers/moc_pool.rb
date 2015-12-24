class MocMixinPool
  include EventMachine::HotTub::Reaper::Mixin
end

class MocPool < MocMixinPool
  attr_accessor :reaped, :lets_reap

  def initialize
    @reaped = false
    @lets_reap = false
    @kill_reaper = false
  end

  def reap!
    @reaped = true if @lets_reap
  end
end

class MocReaperPool < MocPool
  def initialize
    super
    @reaper = EM::HotTub::Reaper.spawn(self)
    @kill_reaper = false
  end
end
