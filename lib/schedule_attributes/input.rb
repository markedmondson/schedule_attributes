require 'schedule_attributes/time_helpers'

module ScheduleAttributes
  class Input

    module RepeatingDates
      def repeat?; true end

      # Defaults to 1
      # @return [Fixnum]
      #
      def interval
        @params.fetch(:interval, 1).to_i
      end

      def interval_unit
        @params[:interval_unit] if repeat?
      end

      def ordinal_unit
        @params[:ordinal_unit].to_sym if @params[:ordinal_unit]
      end

      def ordinal_week
        @params.fetch(:ordinal_week, 1).to_i
      end

      def ordinal_day
        @params.fetch(:ordinal_day, 1).to_i
      end

      def yearly_start_month
        return unless yearly_start_month?
        @params[:yearly_start_month].to_i
      end

      def yearly_end_month
        return unless yearly_end_month?
        @params[:yearly_end_month].to_i
      end

      def yearly_start_month_day
        return unless yearly_start_month_day?
        @params[:yearly_start_month_day].to_i
      end

      def yearly_end_month_day
        return unless yearly_end_month_day?
        @params[:yearly_end_month_day].to_i
      end

      def yearly_start_month?
        @params[:yearly_start_month].present?
      end

      def yearly_end_month?
        @params[:yearly_end_month].present?
      end

      def yearly_start_month_day?
        [ @params[:yearly_start_month].present?,
          @params[:yearly_start_month_day].present?,
          @params[:yearly_start_month_day].to_i > 1
        ].all?
      end

      def yearly_end_month_day?
        @params[:yearly_end_month].present? &&
        @params[:yearly_end_month_day].present? &&
        @params[:yearly_end_month_day].to_i < Time.days_in_month(@params[:yearly_end_month].to_i)
      end

      def weekdays
        IceCube::TimeUtil::DAYS.keys.select { |day| @params[day].to_i == 1 }
      end

      private

      def date_input
        @params[:start_date] || @params[:date]
      end
    end

    module SingleDates
      def repeat?; false end

      private

      def date_input
        @params[:dates] ? @params[:dates].first : @params[:date]
      end
    end

    NEGATIVES = [false, "false", 0, "0", "f", "F", "no", "none"]

    def initialize(params)
      raise ArgumentError "expecting a Hash" unless params.is_a? Hash
      @params = params.symbolize_keys.delete_if { |v| v.blank? }
      date_methods = if NEGATIVES.none? { |v| params[:repeat] == v }
                       RepeatingDates
                     else
                       SingleDates
                     end
      (class << self; self end).send :include, date_methods
    end

    attr_reader :params

    def duration
      return nil unless end_time
      end_time - start_time
    end

    def start_time
      time = @params[:start_time] unless @params[:all_day]
      parse_date_time(date_input, time)
    end

    def end_time
      return nil if @params[:all_day]
      return nil unless @params[:end_time].present?
      parse_date_time(end_time_date, @params[:end_time])
    end

    # if end_time < start_time, the schedule occurs over night
    def end_time_date
      return date_input unless @params[:start_time].present?
      return nil if @params[:all_day]
      return nil unless @params[:end_time].present?
      parse_date_time(date_input, @params[:end_time]) <= start_time ? (Time.parse(date_input) + 1.day).strftime('%Y-%m-%d') : date_input
    end

    def start_date
      if @params[:start_date]
        parse_date_time(@params[:start_date], @params[:start_time])
      elsif @params[:start_time] && !time_only?(@params[:start_time])
        parse_date_time(@params[:start_time])
      elsif start_time
        start_time
      else
        parse_date_time(@params[:start_time])
      end
    end

    def end_date
      if @params[:end_date]
        parse_date_time(@params[:end_date], @params[:end_time] || @params[:start_time])
      elsif @params[:end_time] && !time_only?(@params[:end_time])
        parse_date_time(@params[:end_time])
      elsif end_time
        end_time
      else
        parse_date_time(@params[:end_time])
      end
    end

    def ends?
      return false if @params[:ends] == "never"
      @params[:end_date].present? || @params[:end_time].present?
    end

    def dates
      dates = (@params[:dates] || [@params[:date]]).compact
      time = start_time.strftime('%H:%M') if @params[:start_time]
      dates.map { |d| parse_date_time(d, time) }
    end

    private

    def parse_date_time(date, time=nil)
      date_time_parts = [date, time].compact
      return if date_time_parts.empty?
      TimeHelpers.parse_in_zone(date_time_parts.join(' '))
    end

    def time_only?(string)
      !!(string.strip =~ /\d{1,2}\:\d{2}/)
    end
  end
end
