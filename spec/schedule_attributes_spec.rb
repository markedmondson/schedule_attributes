require 'spec_helper'
require 'support/scheduled_model'

describe ScheduledModel do

  describe "#schedule" do
    subject(:schedule) { ScheduledModel.new.schedule }

    it "should default to a daily schedule" do
      expect(schedule).to be_a(IceCube::Schedule)
      expect(schedule.rtimes).to eq([])
      expect(schedule.start_time).to eq(Date.today.to_time)
      expect(schedule.end_time).to be nil
      expect(schedule.rrules).to eq([IceCube::Rule.daily])
    end
  end

  describe "#schedule_attributes=" do
    describe "setting the correct schedule" do
      let(:scheduled_model) { ScheduledModel.new.tap { |m| m.schedule_attributes = RSpec.current_example.metadata[:args] } }
      subject(:schedule)    { scheduled_model.schedule }

      context "single date", args: {repeat: '0', date: '1-1-1985', interval: '5 (ignore this)'} do
        it { expect(subject.start_time).to eq(Time.new(1985,1,1)) }
        it { expect(subject.all_occurrences).to eq([Time.new(1985,1,1)]) }
        it { expect(subject.rrules).to be_blank }
      end

      context "multiple dates", args: {repeat: '0', dates: ['1-1-1985', '31-12-1985'], interval: '5 (ignore this)'} do
        it { expect(subject.start_time).to eq(Time.new(1985,1,1)) }
        it { expect(subject.all_occurrences).to eq([Time.new(1985,1,1), Time.new(1985,12,31)]) }
        it { expect(subject.rrules).to be_blank }
      end

      context "multiple dates, start and end", args: {repeat: '0', dates: ['1-1-1985', '31-12-1985'], start_time: '12:00', end_time: '14:00', interval: '5 (ignore this)'} do
        it      { expect(subject.start_time).to eq(Time.new(1985,1,1,12,0)) }
        it      { expect(subject.duration).to eq(7200) }
        it      { expect(subject.all_occurrences).to eq([Time.new(1985,1,1,12,0), Time.new(1985,12,31,12,0)]) }
        it      { expect(subject.rrules).to be_blank }
        specify { expect(schedule.occurring_between?(helpers.parse_in_zone('1985-1-1 12:00'), helpers.parse_in_zone('1985-6-25 14:00'))).to be_truthy }
        specify { expect(schedule.occurs_at?(helpers.parse_in_zone('1985-1-1 12:00'))).to be_truthy }
        specify { expect(schedule.occurs_at?(helpers.parse_in_zone('1985-6-6 15:00'))).to be_falsey }
      end

      context "repeats daily", args: {repeat: '1'} do
        it { expect(subject.start_time).to eq(Date.today.to_time) }
        it { expect(subject.rrules).to eq([IceCube::Rule.daily]) }
      end

      context "repeats every 3 days", args: {repeat: '1', start_date: '1-1-1985', interval_unit: 'day', interval: '3'} do
        it      { expect(subject.start_time).to eq(Date.new(1985,1,1).to_time) }
        it      { expect(subject.rrules).to eq([IceCube::Rule.daily(3)]) }
        specify  { expect(schedule.first(3)).to eq([Date.civil(1985,1,1), Date.civil(1985,1,4), Date.civil(1985,1,7)].map(&:to_time)) }
      end

      context "repeats every 3 days with end", args: {repeat: "1", start_date: "1-1-1985", interval_unit: "day", interval: "3", end_date: "29-12-1985", ends: "eventually"} do
        it { expect(subject.start_time).to eq(Date.new(1985,1,1).to_time) }
        # Rails 4.1 removes Date.current.to_time_in_current_zone in favour of Date.in_time_zone
        it do
          if Date.current.respond_to?(:in_time_zone)
            expect(subject.rrules).to eq([ IceCube::Rule.daily(3).until(Date.new(1985,12,29).in_time_zone) ])
          else
            expect(subject.rrules).to eq([ IceCube::Rule.daily(3).until(Date.new(1985,12,29).to_time_in_current_zone) ])
          end
        end
        specify { expect(schedule.first(3)).to eq([Date.civil(1985,1,1), Date.civil(1985,1,4), Date.civil(1985,1,7)].map(&:to_time)) }
      end

      context "repeats every 3 days with until", args: {repeat: '1', start_date: '1-1-1985', interval_unit: 'day', interval: '3', until_date: '29-12-1985', ends: 'never'} do
        it      { expect(subject.start_time).to eq(Date.new(1985,1,1).to_time) }
        it      { expect(subject.rrules).to eq([IceCube::Rule.daily(3)]) }
        specify { expect(schedule.first(3)).to eq([Date.civil(1985,1,1), Date.civil(1985,1,4), Date.civil(1985,1,7)].map(&:to_time)) }
      end

      context "repeats on specific days", args: {repeat: '1', start_date: '1-1-1985', interval_unit: 'week', interval: '3', monday: '1', wednesday: '1', friday: '1'} do
        it      { expect(subject.start_time).to eq(Date.new(1985,1,1).to_time) }
        it      { expect(subject.rrules).to eq([IceCube::Rule.weekly(3).day(:monday, :wednesday, :friday)]) }
        specify { expect(schedule.occurs_at?(helpers.parse_in_zone('1985-1-2'))).to be_truthy }
        specify { expect(schedule.occurs_at?(helpers.parse_in_zone('1985-1-4'))).to be_truthy }
        specify { expect(schedule.occurs_at?(helpers.parse_in_zone('1985-1-7'))).to be_falsey }
        specify { expect(schedule.occurs_at?(helpers.parse_in_zone('1985-1-21'))).to be_truthy }
      end

      context "repeats daily", args: {repeat: '1', start_date: '1-1-1985', interval_unit: 'day'} do
        it { expect(subject.rrules).to eq([IceCube::Rule.daily(1)]) }
      end

      context "repeats yearly", args: {repeat: '1', start_date: '1-1-1985', interval_unit: 'year'} do
        it      { expect(subject.start_time).to eq(Date.new(1985,1,1).to_time) }
        it      { expect(subject.rrules).to eq([IceCube::Rule.yearly.day_of_month(1).month_of_year(1)]) }
        specify { expect(schedule.first(3)).to eq([Date.civil(1985,1,1), Date.civil(1986,1,1), Date.civil(1987,1,1)].map(&:to_time)) }
      end

      context "repeats between range", args: {repeat: '1', interval_unit: 'day', start_date: '2012-09-27', yearly_start_month: '12', yearly_start_month_day: '1', yearly_end_month: '4', yearly_end_month_day: '21'} do
        it { expect(subject.start_time).to eq(Time.new(2012,9,27)) }
        it { expect(subject.rrules).to eq([IceCube::Rule.daily.month_of_year(12,1,2,3,4)]) }
        it { expect(subject.exrules).to eq([IceCube::Rule.daily.month_of_year(4).day_of_month(*22..31)]) }
      end

      context "all_day", pending: "Work in progress"
    end

    describe "setting the schedule field", args: {repeat: '1', start_date: '1-1-1985', interval_unit: 'day', interval: '3'} do
      let(:scheduled_model) { ScheduledModel.new.tap { |m| m.schedule_attributes = RSpec.current_example.metadata[:args] } }
      subject               { scheduled_model }

      it { expect(subject.schedule).to eq(IceCube::Schedule.new(Date.new(1985,1,1).to_time).tap { |s| s.add_recurrence_rule IceCube::Rule.daily(3) })  }
    end

  end

  describe "schedule_attributes" do
    let(:scheduled_model) { ScheduledModel.new }
    let(:schedule)        { IceCube::Schedule.new(Date.tomorrow.to_time) }
    subject               { scheduled_model.schedule_attributes }
    before                { allow(scheduled_model).to receive(:schedule).and_return(schedule) }

    context "for a single date" do
      before { schedule.add_recurrence_time(Date.tomorrow.to_time) }
      it     { is_expected.to eq(OpenStruct.new(all_day: true, repeat: 0, start_date: Date.today, interval: 1, date: Date.tomorrow, dates: [Date.tomorrow])) }
      it     { expect(subject.date).to be_a(Date) }
    end

    context "when it repeats daily" do
      before do
        schedule.add_recurrence_rule(IceCube::Rule.daily(4))
      end
      it { is_expected.to eq(OpenStruct.new(all_day: true, repeat: 1, start_date: Date.tomorrow, interval_unit: 'day', interval: 4, ends: 'never', date: Date.today)) }
      it { expect(subject.start_date).to be_a(Date) }
    end

    context "when it repeats with an end date" do
      before do
        schedule.add_recurrence_rule(IceCube::Rule.daily(4).until((Date.today+10).to_time))
      end
      it { is_expected.to eq(OpenStruct.new(all_day: true, repeat: 1, start_date: Date.tomorrow, interval_unit: 'day', interval: 4, ends: 'eventually', end_date: Date.today+10, date: Date.today)) }
      it { expect(subject.start_date).to be_a(Date) }
      it { expect(subject.end_date).to be_a(Date) }
    end

    context "when it repeats weekly" do
      before do
        schedule.add_recurrence_time(Date.tomorrow)
        schedule.add_recurrence_rule(IceCube::Rule.weekly(4).day(:monday, :wednesday, :friday))
      end
      it do
        is_expected.to eq(OpenStruct.new(
          :repeat        => 1,
          :start_date    => Date.tomorrow,
          :interval_unit => 'week',
          :interval      => 4,
          :ends          => 'never',
          :monday        => 1,
          :wednesday     => 1,
          :friday        => 1,
          :all_day       => true,

          :date          => Date.today #for the form
        ))
      end
    end

    context "when it repeats yearly" do
      before do
        schedule.add_recurrence_time(Date.tomorrow)
        schedule.add_recurrence_rule(IceCube::Rule.yearly)
      end
      it do
        is_expected.to eq(OpenStruct.new(
          :repeat        => 1,
          :start_date    => Date.tomorrow,
          :interval_unit => 'year',
          :interval      => 1,
          :ends          => 'never',
          :all_day       => true,

          :date          => Date.today #for the form
        ))
      end
    end

    context "when it has yearly date range" do
      it "should have yearly start and end months" do
        schedule.add_recurrence_rule(IceCube::Rule.daily.month_of_year(12,1,2))

        expect(subject.yearly_start_month).to eq(12)
        expect(subject.yearly_end_month).to eq(2)
      end

      it "should have a yearly start date" do
        schedule.add_recurrence_rule(IceCube::Rule.daily.month_of_year(11,12,1,2))
        schedule.add_exception_rule(IceCube::Rule.daily.month_of_year(11).day_of_month(*1..6))

        expect(subject.yearly_start_month).to eq(11)
        expect(subject.yearly_start_month_day).to eq(7)
      end

      it "should have a yearly end date" do
        schedule.add_recurrence_rule(IceCube::Rule.daily.month_of_year(1,2,3))
        schedule.add_exception_rule(IceCube::Rule.daily.month_of_year(3).day_of_month(*26..31))

        expect(subject.yearly_end_month).to eq(3)
        expect(subject.yearly_end_month_day).to eq(25)
      end

      it "should have no yearly start day for months only" do
        schedule.add_recurrence_rule(IceCube::Rule.daily.month_of_year(1,2,3))

        expect(subject.yearly_start_month_day).to be_nil
      end

      it "should have a yearly start day on the first when end day is set" do
        schedule.add_recurrence_rule(IceCube::Rule.daily.month_of_year(1,2,3))
        schedule.add_exception_rule(IceCube::Rule.daily.month_of_year(3).day_of_month(*26..31))

        expect(subject.yearly_start_month_day).to eq(1)
      end
    end

    context "all_day", pending: "Work in progress"
  end

  def helpers
    ScheduleAttributes::TimeHelpers
  end
end
