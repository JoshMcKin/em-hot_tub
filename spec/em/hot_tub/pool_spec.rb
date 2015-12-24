
describe EventMachine::HotTub::Pool do

  around(:each) do |example|
    EM.synchrony do
      example.run
      EM.stop
    end
  end

  describe "Mutex" do
    it "should be EM" do
      pool = EM::HotTub::Pool.new {MocClient.new}
      expect(pool.instance_variable_get(:@mutex)).to be_a(EM::Synchrony::Thread::Mutex)
    end
  end

  describe "ConditionVariable" do
    it "should be EM" do
      pool = EM::HotTub::Pool.new {MocClient.new}
      expect(pool.instance_variable_get(:@cond)).to be_a(EM::Synchrony::Thread::ConditionVariable)
    end
  end

  describe "Reaper" do
    it "should be a fiber" do
      pool = EM::HotTub::Pool.new {MocClient.new}
      expect(pool.reaper).to be_a(Fiber)
    end
  end

  context 'EM:HTTPRequest' do
    it "single request" do
      status = []
      c = EM::HotTub::Pool.new {EM::HttpRequest.new(HotTub::Server.url)}
      c.run { |conn| status << conn.head(:keepalive => true).response_header.status}
      c.run { |conn| status << conn.ahead(:keepalive => true).response_header.status}
      c.run { |conn| status << conn.head(:keepalive => true).response_header.status}
      expect(status).to eql([200,0,200])
      c.shutdown!
    end
  end

  context 'pool of fibers' do
    it "should work" do
      pool = EM::HotTub::Pool.new() { EM::HttpRequest.new(HotTub::Server.url) }
      fibers = []
      results  = []
      30.times.each do |i|
        fiber = Fiber.new {
          pool.run do |connection|
            response = connection.get(:keepalive => true)
            results  << response.response_header.status
          end
        }
        fiber.resume
        fibers << fiber
      end
      loop do
        done = true
        fibers.each do |f|
          done = false if f.alive?
        end
        if done
          break
        else
          EM::Synchrony.sleep(0.01)
        end
      end
      expect(results.length).to eql(30) # make sure all responses are present
      expect(results.uniq).to eql([200])
      pool.shutdown!
    end
  end
end
