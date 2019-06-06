require 'spec_helper'
require 'ice_cube'
require 'schedule_attributes/rule_parser'
require 'schedule_attributes/input'

describe ScheduleAttributes::RuleParser::Month do

  describe "#rule" do
    let(:input)  { ScheduleAttributes::Input.new(RSpec.current_example.metadata[:args]) }
    let(:parser) { described_class.new(input) }
    subject      { parser.rule }

    let(:t) { Date.current }
    let(:n) { (t-14 >> 1).change(day: 14) }

    let(:monthly)    { [t, t >> 1, t >> 2, t >> 3].map(&:to_time) }
    let(:bimonthly)  { [t, t >> 2, t >> 4, t >> 6].map(&:to_time) }
    let(:every_14th) { [n, n >> 1, n >> 2, n >> 3].map(&:to_time) }

    context 'no arguments', args: {} do
      it { is_expected.to eq(IceCube::Rule.monthly) }
      it_has_occurrences_until(3.months.from_now) { is_expected.to eq(monthly) }
    end

    context 'start_date and interval arguments', args: {"start_date" => "2000-03-14", "interval" => "2"} do
      it { is_expected.to eq(IceCube::Rule.monthly(2)) }
      it_has_occurrences_until(6.months.from_now) { is_expected.to eq(bimonthly) }
    end

    context 'ordinal_unit and ordinal_day arguments', args: {"ordinal_unit" => "day", "ordinal_day" => "14"} do
      it { is_expected.to eq(IceCube::Rule.monthly.day_of_month(14)) }
      it_has_occurrences_until(4.months.from_now) { is_expected.to eq(every_14th) }
    end

    context 'ordinal_unit, ordinal_week and tuesday arguments', args: {"ordinal_unit" => "week", "ordinal_week" => "2", "tuesday" => "1"} do
      it { is_expected.to eq(IceCube::Rule.monthly.day_of_week(:tuesday => [2])) }
    end

    context 'ordinal_unit and ordinal_week arguments', args: {"ordinal_unit" => "week", "ordinal_week" => "2"} do
      it { is_expected.to eq(IceCube::Rule.monthly.day_of_week(0=>(w=[2]), 1=>w, 2=>w, 3=>w, 4=>w, 5=>w, 6=>w)) }
    end

    context 'start_date and end_date arguments', args: {"start_date" => "2000-03-14", "end_date" => "2000-06-14"} do
      it { is_expected.to eq(IceCube::Rule.monthly.until(Time.new(2000,6,14))) }
    end
  end
end
