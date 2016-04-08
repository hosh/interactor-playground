require 'rlet'
require 'interactor'
require 'kase'
require 'map'

class ChargeIntakeFee
  include Interactor

  def call(context = {})
    return [:error, "Invalid!"] if context[:invalid]
    puts "[charge_intake_fee] execute #{context[:inquiry].id}"
    [:ok, context]
  end
end

class IntakeMailer
  def self.receipt(inquiry:)
    puts "[intake_mailer] queuing receipt for #{inquiry.id}"
  end
end

def charge(inquiry)
  # Let's try composition
  # With Simple, as long as no exception is raised, then return [:ok, context]
  # But if anything goes wrong, such as argument error, or whatver, then return the exception
  # This is really meant for something to override the #handle_error method.

  sequence = ChargeIntakeFee \
             | Interactors::Simple.new { |context| IntakeMailer.receipt(inquiry: context[:inquiry]) }

  Kase.kase sequence.call(inquiry: inquiry) do
    on(:ok)    { |_| puts "Thank you" }
    on(:error) { |reason| puts "Error: #{reason}" }
  end
end

charge(Map.new(id: '123'))
charge(Map.new(id: '123', invalid: true))

