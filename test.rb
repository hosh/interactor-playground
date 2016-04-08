require 'rlet'
require 'interactor'
require 'kase'
require 'map'

class ChargeIntakeFee
  include Interactor

  def call(context = {})
    puts "[charge_intake_fee] execute #{context[:inquiry].id}"
    [:ok, context]
  end
end

class IntakeMailer
  def self.receipt(inquiry:)
    puts "[intake_mailer] queuing receipt for #{inquiry.id}"
  end
end

inquiry = Map.new(id: '123')

# Let's try composition
sequence = ChargeIntakeFee \
           | Interactors::Simple.new { |context| IntakeMailer.receipt(inquiry: context[:inquiry]) }

# With Simple, as long as no exception is raised, then return [:ok, context]
# But if anything goes wrong, such as argument error, or whatver, then return the exception
# This is really meant for something to override the #handle_error method.

puts sequence.inspect
puts sequence.interactions.inspect

sequence.call(inquiry: inquiry)
