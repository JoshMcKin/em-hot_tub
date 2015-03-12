module EventMachine::HotTub
  class Reaper
    def self.spawn(obj)
      fiber = Fiber.new {
      	Thread.current[:name] = "EM::HotTub::Reaper"
        loop do
          begin
            obj.reap!
            break if obj.shutdown
            Fiber.yield 
          rescue Exception => e
            HotTub.logger.error "HotTub::Reaper for #{obj.class.name} terminated with exception: #{e.message}"
            HotTub.logger.error e.backtrace.map {|line| " #{line}"}
            break
          end
        end
      }
      fiber
    end
  end
end
