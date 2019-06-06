require 'spec_helper'
require 'schedule_attributes/time_helpers'
require 'active_support/time_with_zone'

describe ScheduleAttributes::TimeHelpers do
  describe '.parse_in_zone' do

    context "with time zone" do
      before { Time.zone = 'UTC' }

      it "returns a time from a date string" do
        expect(subject.parse_in_zone("2000-12-31")).to eq(Time.zone.parse("2000-12-31"))
      end

      it "returns a time from a time" do
        local_offset = "-08:00"
        local_time = Time.new(2000,12,31,0,0,0,local_offset)
        expect(subject.parse_in_zone(local_time)).to eq(Time.zone.parse("2000-12-31 08:00:00"))
      end

      it "returns a time from a date" do
        expect(subject.parse_in_zone(Date.new(2000,12,31))).to eq(Time.zone.parse("2000-12-31"))
      end
    end

    context "without ActiveSupport" do
      before { Time.zone = nil }

      it "returns a time from a date string" do
        expect(subject.parse_in_zone("2000-12-31")).to eq(Time.parse("2000-12-31"))
      end

      it "returns a time from a time" do
        expect(subject.parse_in_zone(Time.new(2000,12,31))).to eq(Time.parse("2000-12-31"))
      end
    end

  end
end
