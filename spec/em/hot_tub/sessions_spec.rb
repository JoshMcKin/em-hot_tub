require 'spec_helper'
require 'uri'
require 'time'
describe EM::HotTub::Sessions do

  around(:each) do |example|
    EM.synchrony do
      example.run
      EM.stop
    end
  end

  describe "Mutex" do
    it "should be EM" do
      sessions = EM::HotTub::Sessions.new()
      expect(sessions.instance_variable_get(:@mutex)).to be_a(EM::Synchrony::Thread::Mutex)
    end
  end

  describe '#run' do
    it "should work" do
      url = HotTub::Server.url
      sessions = EM::HotTub::Sessions.new
      sessions.add(url) { EM::HttpRequest.new(url) }
      result = nil
      sessions.run(url) do |conn|
        result = conn.get.response_header.status
      end
      expect(result).to eql(200)
    end
  end

  describe '#clean!' do
    it "should clean all pools in sessions" do
      sessions = EM::HotTub::Sessions.new()
      sessions.add('foo', :clean => lambda { |clnt| clnt.clean}) { MocClient.new }
      sessions.add('bar', :clean => lambda { |clnt| clnt.clean}) { MocClient.new }
      sessions.clean!
      sessions.instance_variable_get(:@_sessions).each_pair do |k,v|
        v.instance_variable_get(:@_pool).each do |c|
          expect(c).to be_cleaned
        end
      end
    end
  end

  describe '#drain!' do
    context "with_pool" do
      it "should drain all pools in sessions" do
        sessions = EM::HotTub::Sessions.new(:with_pool => true) { |url| MocClient.new(url) }
        sessions.add('foo') { MocClient.new }
        sessions.add('bar') { MocClient.new }
        sessions.drain!
        sessions.instance_variable_get(:@_sessions).each_pair do |k,v|
          expect(v.instance_variable_get(:@_pool)).to be_empty
        end
      end
    end
  end

  describe '#reap!' do
    it "should clean all pools in sessions" do
      sessions = EM::HotTub::Sessions.new
      sessions.add('foo', :reap => lambda { |clnt| clnt.reap}) { MocClient.new }
      sessions.add('bar', :reap => lambda { |clnt| clnt.reap}) { MocClient.new }
      sessions.reap!
      sessions.instance_variable_get(:@_sessions).each_pair do |k,v|
        v.instance_variable_get(:@_pool).each do |c|
          expect(c).to be_reaped
        end
      end
    end
  end

  context 'integration tests' do
    it "should work" do
      url = HotTub::Server.url
      url2 = HotTub::Server2.url
      session = EM::HotTub::Sessions.new()
      session.add(url) { EM::HttpRequest.new(url, {:max_size => 10}) }
      session.add(url2) { EM::HttpRequest.new(url2, {:max_size => 10}) }

      fibers = []
      results  = []
      30.times.each do
        fiber = Fiber.new do
          session.run(url)  { |clnt| results << clnt.get.response_header.status }
          session.run(url2) { |clnt| results << clnt.get.response_header.status }
        end
        fiber.resume
        fibers << fiber
      end

      # Wait until work is done
      while fibers.detect(&:alive?)
        EM::Synchrony.sleep(0.01)
      end

      expect(results.length).to eql(60) # make sure all responses are present
      expect(results.uniq).to eql([200,0]) # Em http request gives 0 status randomly
      expect(session.instance_variable_get(:@_sessions).keys.length).to eql(2) # make sure sessions were created
    end
  end
end
