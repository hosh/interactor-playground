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

class SendReceipt
  include Interactor

  def call(context = {})
    IntakeMailer.receipt(inquiry: context[:inquiry])
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

sequence = (ChargeIntakeFee | SendReceipt)
puts sequence.inspect
puts sequence.interactions.inspect

sequence.call(inquiry: inquiry)
