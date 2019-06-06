require 'active_support'
require 'ostruct'
require 'pry'
require 'support/parser_macros'

$: << File.expand_path('../lib')

RSpec.configure do |config|
  config.include SpecHelpers::ParserMacros
  config.expect_with :rspec
end
