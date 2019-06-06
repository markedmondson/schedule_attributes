require 'spec_helper'
require 'ice_cube'
require 'schedule_attributes/rule_parser'
require 'schedule_attributes/input'

describe ScheduleAttributes::RuleParser::Year do
  let(:t) { Date.today }
  let(:n) { Date.new(Date.current.year,3,14) }

  let(:every_year)     { [t, t>>12, t>>24, t>>36, t>>48].map(&:to_time) }
  let(:every_2nd_year) { [t, t>>24, t>>48].map(&:to_time) }
  let(:every_pi_day)   { [n, n>>12, n>>24, n>>36, n>>48].tap{ |a| a.shift if t.yday > n.yday }.map(&:to_time) }

  describe "#rule" do
    let(:input)  { ScheduleAttributes::Input.new(RSpec.current_example.metadata[:args]) }
    let(:parser) { described_class.new(input) }
    subject      { parser.rule }

    context 'no arguments', args: {} do
      it { is_expected.to eq(IceCube::Rule.yearly) }
      it_has_occurrences_until(4.years.from_now) { is_expected.to eq(every_year) }
    end

    context 'interval argument', args: {"interval" => "2"} do
      it { is_expected.to eq(IceCube::Rule.yearly(2)) }
      it_has_occurrences_until(4.years.from_now) { is_expected.to eq(every_2nd_year) }
    end

    context 'start_date argument', args: {"start_date" => "2000-03-14"} do
      it { is_expected.to eq(IceCube::Rule.yearly.month_of_year(3).day_of_month(14)) }
    end

    context 'start_date argument alt', args: {"start_date" => "2000-01-30"} do
      it { is_expected.to eq(IceCube::Rule.yearly.month_of_year(1).day_of_month(30)) }
    end

    context 'start_date and end_date arguments', args: {"start_date" => "2000-03-14", "end_date" => "#{Date.current.year+4}-03-14"} do
      it { is_expected.to eq(IceCube::Rule.yearly.month_of_year(3).day_of_month(14).until(Date.new(Date.current.year+4,3,14).to_time)) }
      it_has_occurrences_until(10.years.from_now) { is_expected.to eq(every_pi_day) }
    end

    context "ignoring yearly_start and end limits", args: {
      "start_date"             => "2000-03-14",
      "yearly_start_month"     => "4",
      "yearly_start_month_day" => "15",
      "yearly_end_month"       => "5",
      "yearly_end_month_day"   => "20"
    } do
      it { is_expected.to eq(IceCube::Rule.yearly.month_of_year(3).day_of_month(14)) }
      it_has_occurrences_until(Date.new(Date.current.year+4,12,31)) { is_expected.to eq(every_pi_day) }
    end
  end
end
