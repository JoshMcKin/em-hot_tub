require 'spec_helper'

describe EventMachine::HotTub::Reaper do
  around(:each) do |example|
    EM.synchrony do
      example.run
      EM.stop
    end
  end

  let(:pool) { MocReaperPool.new }
  let(:reaper) { pool.reaper }

  it { reaper.should be_a(Fiber) }


  it "should reap!" do

    pool.reaped.should eql(false)
    pool.lets_reap = true
    reaper.resume
    EM::Synchrony.sleep(0.01)
    expect(pool.reaped).to eql(true)
  end
end
