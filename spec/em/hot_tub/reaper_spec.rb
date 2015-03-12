require 'spec_helper'

describe EventMachine::HotTub::Reaper do
  around(:each) do |example|
    EM.synchrony do
      @pool = MocReaperPool.new
      @reaper = @pool.reaper

      example.run
      EM.stop
    end
  end

  it { @reaper.should be_a(Fiber) }


  it "should reap!" do

    @pool.reaped.should eql(false)
    @pool.lets_reap = true
    @reaper.resume
    sleep(0.01)
    @pool.reaped.should eql(true)
  end
end
