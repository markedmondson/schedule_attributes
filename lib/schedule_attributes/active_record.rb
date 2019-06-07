require 'schedule_attributes/core'
require 'schedule_attributes/serializer'

module ScheduleAttributes::ActiveRecord
  extend ActiveSupport::Concern
  include ScheduleAttributes::Core

  module ClassMethods
    attr_accessor :schedule_field
    attr_writer   :default_schedule

    def default_schedule
      @default_schedule = case @default_schedule
      when Proc
        @default_schedule.call
      when Symbol, String
        self.public_send(@default_schedule)
      end if @default_schedule

      @default_schedule || ScheduleAttributes.default_schedule
    end
  end

  module Sugar
    def has_schedule_attributes(options={:column_name => :schedule})
      options[:column_name] ||= ScheduleAttributes::DEFAULT_ATTRIBUTE_KEY
      @schedule_field = options[:column_name]
      @default_schedule = options[:default_schedule] if options.has_key?(:default_schedule)
      serialize @schedule_field, ScheduleAttributes::Serializer
      include ScheduleAttributes::ActiveRecord
    end
  end

  private

  def initialize(*args)
    super
    self[self.class.schedule_field] ||= default_schedule
  end

  def read_schedule_field
    self[self.class.schedule_field] or default_schedule
  end

  def write_schedule_field(value)
    self[self.class.schedule_field] = value
  end

  def default_schedule
    self.class.default_schedule
  end
end

# Injects the has_schedule_attributes method when loading without Rails
if defined? ActiveRecord::Base
  ActiveRecord::Base.send :extend, ScheduleAttributes::ActiveRecord::Sugar
end
