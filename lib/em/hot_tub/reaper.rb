module EventMachine::HotTub
  class Reaper
    def self.spawn(obj)
      fiber = Fiber.new {
        Thread.current[:name] = "EventMachine::HotTub::Reaper"
        while true do
          break if obj.kill_reaper?
          begin
            obj.reap!
            break if obj.shutdown
            #Fiber.yield
            EM::Synchrony.sleep(obj.reap_timeout)
          rescue Exception => e
            HotTub.logger.error "HotTub::Reaper for #{obj.class.name} terminated with exception: #{e.message}"
            HotTub.logger.error e.backtrace.map {|line| " #{line}"}
            break
          end
        end
      }
      fiber
    end

    # Mixin to dry up Reaper usage
    module Mixin
      attr_reader :reap_timeout, :shutdown, :reaper

      # Setting reaper kills the current reaper.
      # If the values is truthy a new HotTub::Reaper
      # is created.
      def reaper=reaper
        kill_reaper
        if reaper
          @reaper = EventMachine::HotTub::Reaper.new(self)
        else
          @reaper = false
        end
      end

      def kill_reaper?
        @kill_reaper
      end

      def kill_reaper
        @kill_reaper = true
        @reaper.resume if @reaper && @reaper.alive?
        @reaper = nil if @shutdown
      end

      def spawn_reaper
        @kill_reaper = false
        EventMachine::HotTub::Reaper.spawn(self)
      end
    end
  end
end
