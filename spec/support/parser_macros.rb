module SpecHelpers
  module ParserMacros
    extend ActiveSupport::Concern

    module ClassMethods
      def it_has_occurrences_until(date, &block)
        describe "occurrences" do
          shared_examples "occurrences" do

            orig_subject = subject

            self.class.class_eval do
              define_method(:subject) do
                schedule = IceCube::Schedule.new(Date.today.to_time)
                schedule.add_recurrence_rule(orig_subject)
                @_subject = schedule.occurrences(date)
              end
            end

            yield
          end
        end
      end
    end

  end
end
