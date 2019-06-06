require 'spec_helper'
require 'ice_cube'
require 'schedule_attributes/rule_parser'
require 'schedule_attributes/input'

describe ScheduleAttributes::RuleParser::Week do
  let(:t)   { Date.current.to_time }
  let(:sun) { (Date.current - Date.current.cwday.days).to_time + 1.week }
  let(:mon) { sun + 1.day }
  let(:sat) { sun - 1.day }

  let(:weekly)        { [t, t+1.week, t+2.weeks, t+3.weeks, t+4.weeks, t+5.weeks] }
  let(:every_2_weeks) { [t, t+2.week, t+4.weeks]}
  let(:weekends)      { [sat, sun, sat+1.week, sun+1.week, sat+2.weeks, sun+2.weeks] }

  describe "#rule" do
    let(:input)  { ScheduleAttributes::Input.new(RSpec.current_example.metadata[:args]) }
    let(:parser) { described_class.new(input) }
    subject      { parser.rule }

    context 'no arguments', args: {} do
      it { is_expected.to eq(IceCube::Rule.weekly) }
      it_has_occurrences_until(5.weeks.from_now) { is_expected.to eq(weekly) }
    end

    context 'interval argument', args: {"interval" => "2"} do
      it { is_expected.to eq(IceCube::Rule.weekly(2)) }
      it_has_occurrences_until(5.weeks.from_now) { is_expected.to eq(every_2_weeks) }
    end

    context 'several day name arguments', args: {"monday" => "0", "saturday" => "1", "sunday" => "1"} do
      it { is_expected.to eq(IceCube::Rule.weekly.day(0,6)) }
      it_has_occurrences_until(Date.today.beginning_of_week+3.weeks) { expect(subject[-4..-1]).to eq weekends[-4..-1] }
    end
  end
end
