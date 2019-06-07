require 'spec_helper'
require 'support/scheduled_active_record_model'


describe CustomScheduledActiveRecordModel do

  it "should have a default schedule" do
    expect(subject.my_schedule).to eq(hourly)
  end

  def hourly
    IceCube::Schedule.new(Date.today.to_time).tap { |s|
      s.add_recurrence_rule IceCube::Rule.hourly
    }
  end

end

describe CustomScheduledMethodActiveRecordModel do

  it "should have a default schedule" do
    subject.schedule.should == today
  end

  def today
    IceCube::Schedule.new(Date.today.to_time).tap { |s|
      s.add_recurrence_rule IceCube::SingleOccurrenceRule.new(Date.today)
    }
  end

end

describe DefaultScheduledActiveRecordModel do
  alias :model :subject

  it "should have a default schedule" do
    expect(subject.schedule).to be_a IceCube::Schedule
  end


  describe "schedule_attributes" do
    it "round-trips a schedule from the database" do
      model.schedule_attributes = {
        "repeat"=>"1", "date"=>"",
        "start_date"=>"2013-02-26", "start_time"=>"",
        "end_date"=>"2016-07-07",   "end_time"=>"",
        "ordinal_day"=>"1",         "interval"=>"3",
        "ordinal_week"=>"1",        "interval_unit"=>"day",
        "sunday"=>"0",   "monday"=>"0", "tuesday"=>"0", "wednesday"=>"0",
        "thursday"=>"0", "friday"=>"0", "saturday"=>"0"
      }
      expected = IceCube::Schedule.new(Time.local(2013, 2, 26)) do |s|
        s.rrule IceCube::Rule.daily(3).until(Time.local(2016, 7, 7))
      end
      expect(model.schedule).to eq(expected)
    end
  end

end
