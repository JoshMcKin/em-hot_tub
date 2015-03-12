
describe EventMachine::HotTub::Pool do

  around(:each) do |example|
    EM.synchrony do
      @url = HotTub::Server.url

      example.run

      EM.stop
    end
  end


  context 'EM:HTTPRequest' do
    it "single request" do
      status = []
      c = EM::HotTub::Pool.new {EM::HttpRequest.new(@url)}
      c.run { |conn| status << conn.head(:keepalive => true).response_header.status}
      c.run { |conn| status << conn.ahead(:keepalive => true).response_header.status}
      c.run { |conn| status << conn.head(:keepalive => true).response_header.status}
      expect(status).to eql([200,0,200])
      c.shutdown!
    end
  end

  context 'pool of fibers' do
    it "should work" do
      pool = EM::HotTub::Pool.new({:size => 5, :max_size => 5}) { EM::HttpRequest.new(@url) }
      failed = false
      fibers = []
      30.times.each do |i|
        fiber = Fiber.new {
          pool.run do |connection|
            response = connection.get(:keepalive => true)
            #puts "#{i}-#{response.response.length}"
            code = response.response_header.status
            failed = true unless code == 200
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
      expect(pool.instance_variable_get(:@pool).length).to be >= 5 #make sure work got done
      expect(failed).to eql(false) # Make sure our requests worked
      pool.shutdown!
    end
  end
end
