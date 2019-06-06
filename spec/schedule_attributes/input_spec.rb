require 'spec_helper'
require 'schedule_attributes/input'

describe ScheduleAttributes::Input do
  let(:input) { described_class.new(RSpec.current_example.metadata[:args]) }

  describe "#repeat?" do
    subject(:repeat) { input.repeat? }

    context 'no arguments', args: {} do
      it { is_expected.to be true }
    end

    [0, '0', 'false', 'f', 'F', 'no', 'none'].each do |cond|
      context 'false', args: {repeat: cond} do
        it { is_expected.to be false }
      end
    end

    [1, '1', 'true', 't', 'T', 'yes', 'whatever'].each do |cond|
      context 'true', args: {repeat: cond} do
        it { is_expected.to be true }
      end
    end
  end

  describe "#start_time" do
    subject(:start_time) { input.start_time }

    context 'no arguments', args: {} do
      it { is_expected.to be nil }
    end

    context 'date argument', args: {date: '2000-12-31'} do
      it { is_expected.to eq(Time.new(2000,12,31,0,0,0)) }
    end

    context 'start_date argument', args: {start_date: '2000-12-31'} do
      it { is_expected.to eq(Time.new(2000,12,31,0,0,0)) }
    end

    context 'date and start_date arguments', args: {date: '2000-06-06', start_date: '2000-12-31'} do
      it { is_expected.to eq(Time.new(2000,12,31,0,0,0)) }
    end

    context 'both dates and repeat arguments', args: {repeat: '0', date: '2000-06-06', start_date: '2000-12-31'} do
      it "uses date instead of start_date when not repeating" do
        is_expected.to eq(Time.new(2000,6,6,0,0,0))
      end
    end

    context 'start_date and start_time arguments', args: {start_date: '2000-12-31', start_time: '14:30'} do
      it "combines start_date and start_time" do
        is_expected.to eq(Time.new(2000,12,31,14,30,0))
      end
    end

    context 'start_time argument', args: {start_time: '14:00'} do
      it { is_expected.to eq(Date.today.to_time + 14.hours) }
    end
  end

  describe "#end_time" do
    subject(:end_time) { input.end_time }

    context 'no arguments', args: {} do
      it { is_expected.to be nil }
    end

    context 'end_time argument', args: {end_time: '14:00'} do
      it { is_expected.to eq(Date.today.to_time + 14.hours) }
    end

    context 'start_date and end_time arguments', args: {start_date: '2000-12-31', end_time: '14:00'} do
      it { is_expected.to eq(Time.new(2000,12,31,14,0,0)) }
    end

    context 'start_date, end_date and end_time arguments', args: {start_date: '2000-06-06', end_date: '2000-12-31', end_time: '14:00'} do
      it { is_expected.to eq(Time.new(2000,6,6,14,0,0)) }
    end

    context 'date and end_time arguments', args: {date: '2000-12-31', end_time: '14:00'} do
      it { is_expected.to eq(Time.new(2000,12,31,14,0,0)) }
    end

    context 'start_date and _time and end_date and _time arguments', args: {start_date: '2000-06-06', end_date: '2000-12-31', start_time: '06:00', end_time: '14:00'} do
      it { is_expected.to eq(Time.new(2000,6,6,14,0,0)) }
    end

    context 'start_date and _time and end_date and _time arguments, 24h format', args: {start_date: '2000-06-06', end_date: '2000-12-31', start_time: '20:00', end_time: '14:00'} do
      it { is_expected.to eq(Time.new(2000,6,7,14,0,0)) }
    end
  end

  describe "#duration" do
    subject(:duration) { input.duration }

    context 'no arguments', args: {} do
      it { is_expected.to be nil }
    end

    context 'start_time argument', args: {start_time: '8:00'} do
      it { is_expected.to be nil }
    end

    context 'start_time and end_time arguments', args: {start_time: '8:00', end_time: '14:00'} do
      it { is_expected.to eq(6.hours) }
    end
  end

  describe "#dates" do
    subject(:dates) { input.dates }

    context 'no arguments', args: {} do
      it { is_expected.to eq([]) }
    end

    context 'repeat argument', args: {repeat: '0'} do
      it { is_expected.to eq([]) }
    end

    context 'start_date argument', args: {start_date: '2000-06-06'} do
      it { is_expected.to eq([]) }
    end

    context 'repeat, date and start_date arguments', args: {repeat: '0', date: '2000-06-06', start_date: '2000-02-03'} do
      it { is_expected.to eq([Time.new(2000,6,6)]) }
    end

    context 'dates array argument', args: {dates: ['2000-01-02','2000-02-03']} do
      it { is_expected.to eq([Time.new(2000,1,2), Time.new(2000,2,3)]) }
    end

    context 'repeat, date, start_date and start_time arguments', args: {repeat: '0', date: '2000-06-06', start_date: '2000-06-06', start_time: '12:00'} do
      it { is_expected.to eq([Time.new(2000,6,6,12,0)]) }
    end
  end

  describe "#ends?" do
    subject(:ends) { input.ends? }

    context 'repeat and end_date arguments', args: {repeat: '1', end_date: ''} do
      it { is_expected.to be_falsey }
    end
  end

  describe "#yearly_start_month_day?" do
    subject(:yearly_start_month_day) { input.yearly_start_month_day? }

    context 'repeat and yearly_start_month_day arguments', args: {repeat: '1', yearly_start_month_day: '2'} do
      it { is_expected.to be_falsey }
    end

    context 'repeat, yearly_start_month and yearly_start_month_day arguments', args: {repeat: '1', yearly_start_month: '12', yearly_start_month_day: '2'} do
      it { is_expected.to be_truthy }
    end

    context 'repeat, yearly_start_month and yearly_start_month_day arguments', args: {repeat: '1', yearly_start_month: '12', yearly_start_month_day: '1'} do
      it { is_expected.to be_falsey }
    end
  end

  describe "#yearly_end_month_day?" do
    subject(:yearly_end_month_day) { input.yearly_end_month_day? }

    context 'repeat and yearly_end_month_day arguments', args: {repeat: '1', yearly_end_month_day: '27'} do
      it { is_expected.to be_falsey }
    end

    context 'repeat, yearly_end_month and yearly_end_month_day arguments', args: {repeat: '1', yearly_end_month: '12', yearly_end_month_day: '27'} do
      it { is_expected.to be_truthy }
    end

    context 'repeat, yearly_end_month and yearly_end_month_day arguments', args: {repeat: '1', yearly_end_month: '12', yearly_end_month_day: '31'} do
      it { is_expected.to be_falsey }
    end

    context 'repeat, yearly_end_month and yearly_end_month_day arguments', args: {repeat: '1', yearly_end_month: '11', yearly_end_month_day: '30'} do
      it { is_expected.to be_falsey }
    end
  end
end
