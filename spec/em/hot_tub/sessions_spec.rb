require 'spec_helper'
require 'uri'
require 'time'
describe EM::HotTub::Sessions do
  around(:each) do |example|
    EM.synchrony do
      @pool = MocReaperPool.new
      @reaper = @pool.reaper

      example.run
      EM.stop
    end
  end

  describe '#run' do
    it "should work" do
      url = HotTub::Server.url
      sessions = EM::HotTub::Sessions.new { |url| EM::HttpRequest.new(url) }
      result = nil
      sessions.run(url) do |conn|
        result = conn.get.response_header.status
      end
      expect(result).to eql(200)
    end

    context "with_pool" do
      it "should work" do
        url = HotTub::Server.url
        session_with_pool = EM::HotTub::Sessions.new({:with_pool => true})  { |url|
          EM::HttpRequest.new(url)
        }
        result = nil
        session_with_pool.run(url) do |conn|
          result = conn.get.response_header.status
        end
        expect(result).to eql(200)
      end
    end
  end

  describe '#clean!' do
    it "should clean all sessions" do
      sessions = EM::HotTub::Sessions.new(:clean => lambda { |clnt| clnt.clean}) { |url| MocClient.new(url) }
      sessions.sessions('foo')
      sessions.sessions('bar')
      sessions.clean!
      sessions.instance_variable_get(:@sessions).each_pair do |k,v|
        expect(v).to be_cleaned
      end
    end
    context "with_pool" do
      it "should clean all pools in sessions" do
        sessions = EM::HotTub::Sessions.new(:with_pool => true, :clean => lambda { |clnt| clnt.clean}) { |url| MocClient.new(url) }
        sessions.sessions('foo')
        sessions.sessions('bar')
        sessions.clean!
        sessions.instance_variable_get(:@sessions).each_pair do |k,v|
          v.instance_variable_get(:@pool).each do |c|
            expect(c).to be_cleaned
          end
        end
      end
    end
  end

  describe '#drain!' do
    it "should drain all sessions" do
      sessions = EM::HotTub::Sessions.new { |url| MocClient.new(url) }
      sessions.sessions('foo')
      sessions.sessions('bar')
      sessions.drain!
      expect(sessions.instance_variable_get(:@sessions)).to be_empty
    end
    context "with_pool" do
      it "should drain all pools in sessions" do
        sessions = EM::HotTub::Sessions.new(:with_pool => true) { |url| MocClient.new(url) }
        sessions.sessions('foo')
        sessions.sessions('bar')
        sessions.drain!
        expect(sessions.instance_variable_get(:@sessions)).to be_empty
      end
    end
  end

  describe '#reap!' do
    it "should clean all sessions" do
      sessions = EM::HotTub::Sessions.new(:reap => lambda { |clnt| clnt.reap}) { |url| MocClient.new(url) }
      sessions.sessions('foo')
      sessions.sessions('bar')
      sessions.reap!
      sessions.instance_variable_get(:@sessions).each_pair do |k,v|
        expect(v).to be_reaped
      end
    end
    context "with_pool" do
      it "should clean all pools in sessions" do
        sessions = EM::HotTub::Sessions.new(:with_pool => true, :reap => lambda { |clnt| clnt.reap}) { |url| MocClient.new(url) }
        sessions.sessions('foo')
        sessions.sessions('bar')
        sessions.reap!
        sessions.instance_variable_get(:@sessions).each_pair do |k,v|
          v.instance_variable_get(:@pool).each do |c|
            expect(c).to be_reaped
          end
        end
      end
    end
  end

  context 'integration tests' do
    it "should work" do
      url = HotTub::Server.url
      url2 = HotTub::Server2.url
      session = EM::HotTub::Sessions.new(:with_pool => true, :size => 5, :max_size => 5) { |url|
        EM::HttpRequest.new(url)
      }
      failed = false
      fibers = []
      results  = []
      30.times.each do
        fiber = Fiber.new do
          session.run(url)  { |clnt| results << clnt.get.response_header.status }
          session.run(url2) { |clnt| results << clnt.get.response_header.status}
        end
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
      expect(results.length).to eql(60) # make sure all threads are present
      expect(results.uniq).to eql([200,0]) # Em http request gives 0 status randomly
      expect(session.instance_variable_get(:@sessions).keys.length).to eql(2) # make sure sessions were created
      session.shutdown!
    end
  end
end
