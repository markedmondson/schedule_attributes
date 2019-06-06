require 'spec_helper'
require 'ice_cube'
require 'schedule_attributes/rule_parser'
require 'schedule_attributes/input'

describe ScheduleAttributes::RuleParser::Day do
  let(:input)  { ScheduleAttributes::Input.new(RSpec.current_example.metadata[:args]) }
  let(:parser) { described_class.new(input) }
  let(:t)      { Date.current.to_time }

  describe "#rule" do
    subject      { parser.rule }

    context 'no arguments', args: {} do
      let(:every_day) { [t, t+1.day, t+2.days, t+3.days, t+4.days, t+5.days, t+6.days, t+7.days, t+8.days] }

      it { is_expected.to eq(IceCube::Rule.daily) }
      it_has_occurrences_until(8.days.from_now) { is_expected.to eq(every_day) }
    end

    context 'interval argument', args: {interval: 2} do
      let(:every_other_day) { [t, t+2.days, t+4.days, t+6.days, t+8.days] }

      it { is_expected.to eq(IceCube::Rule.daily(2)) }
      it_has_occurrences_until(8.days.from_now) { is_expected.to eq(every_other_day) }
    end

    context 'end_date argument', args: {end_date: '2014-01-30'} do
      let(:t)           { Time.new(2014,01,30) }
      let(:last_5_days) { [t-4.days, t-3.days, t-2.days, t-1.day, t] }

      it { is_expected.to eq(IceCube::Rule.daily.until(t)) }
      it_has_occurrences_until(Time.new(2014,02,01)) { expect(subject[-5..-1]).to eq last_5_days }
    end

    context 'yearly_start_month and yearly_end_month arguments, whole year', args: {yearly_start_month: 1, yearly_end_month: 12} do
      it { is_expected.to eq(IceCube::Rule.daily) }
    end

    context 'yearly_start_month and yearly_end_month arguments, less than a year', args: {yearly_start_month: 6, yearly_end_month: 8} do
      it { is_expected.to eq(IceCube::Rule.daily.month_of_year(6,7,8)) }
    end

    context 'yearly_start_month and yearly_end_month arguments, jump year', args: {yearly_start_month: 11, yearly_end_month: 1} do
      it { is_expected.to eq(IceCube::Rule.daily.month_of_year(11,12,1)) }
    end

    context 'yearly_start_month and yearly_end_month arguments, jump year alt', args: {yearly_start_month: 12, yearly_end_month: 2} do
      it { is_expected.to eq(IceCube::Rule.daily.month_of_year(12,1,2)) }
    end

    context 'yearly_start_month, yearly_start_month_day, yearly_end_month and yearly_end_month_day arguments', args: {
      yearly_start_month: 3, yearly_start_month_day: 14,
      yearly_end_month:   3, yearly_end_month_day:   17
    } do
      it { is_expected.to eq(IceCube::Rule.daily.month_of_year(3)) }
    end
  end

  describe "#exceptions" do
    subject      { parser.exceptions }

    context 'yearly_start_month, yearly_start_month_day, yearly_end_month and yearly_end_month_day arguments', args: {
      yearly_start_month: 3, yearly_start_month_day: 4,
      yearly_end_month:   3, yearly_end_month_day:   26
    } do
      it "returns exceptions for the leading & trailing days" do
        is_expected.to eq([
          IceCube::Rule.daily.month_of_year(3).day_of_month(*1..3),
          IceCube::Rule.daily.month_of_year(3).day_of_month(*27..31)
        ])
      end
    end

    context 'yearly_start_month and yearly_end_month arguments', args: {yearly_start_month: 3, yearly_end_month: 3} do
      it "has no trailing exceptions" do
        is_expected.to eq([])
      end
    end

    context 'yearly_start_month, yearly_end_month and yearly_end_month_day arguments', args: {yearly_start_month: 3, yearly_end_month: 4, yearly_end_month_day: 25} do
      it "returns exceptions for the trailing days of the last month only" do
        is_expected.to eq([IceCube::Rule.daily.month_of_year(4).day_of_month(*26..31)])
      end
    end

    context 'yearly_start_month, yearly_start_month_day and yearly_end_month arguments', args: {yearly_start_month: 3, yearly_start_month_day: 3, yearly_end_month: 4} do
      it "returns exceptions for the leading days of the first month" do
        is_expected.to eq([
          IceCube::Rule.daily.month_of_year(3).day_of_month(*1..2)
        ])
      end
    end

    context 'yearly_start_month, yearly_end_month, yearly_start_month_day and yearly_end_month_day arguments', args: {yearly_start_month: 3, yearly_end_month: 4, yearly_start_month_day: 31, yearly_end_month_day: 1} do
      it "excepts the first 30 days of first month and last 30 days of last month" do
        is_expected.to eq([
          IceCube::Rule.daily.month_of_year(3).day_of_month(*1..30),
          IceCube::Rule.daily.month_of_year(4).day_of_month(*2..31)
        ])
      end
    end

    context 'yearly_start_month, yearly_end_month, yearly_start_month_day and yearly_end_month_day arguments', args: {yearly_start_month: 12, yearly_end_month: 1, yearly_start_month_day: 31, yearly_end_month_day: 1} do
      it "excepts the first 30 days of first month and last 30 days of last month" do
        is_expected.to eq([
          IceCube::Rule.daily.month_of_year(12).day_of_month(*1..30),
          IceCube::Rule.daily.month_of_year(1).day_of_month(*2..31)
        ])
      end
    end
  end
end
