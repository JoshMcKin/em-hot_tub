require 'spec_helper'

describe EventMachine::HotTub do

	describe '#new' do

		it { expect(EventMachine::HotTub.new { MocClient.new }).to be_a(EventMachine::HotTub::Pool) }
	end

end
