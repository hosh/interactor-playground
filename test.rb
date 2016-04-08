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

# Generic Mail Interactor
class SendMail
  attr_reader :mailer_klass, :mailer_method

  def initialize(klass, method_name)
    @mailer_klass = klass
    @mailer_method = method_name
  end

  def call(context)
    mailer_klass.send(mailer_method, *context)
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
           | Interactors.new do |context|
               IntakeMailer.receipt(inquiry: context[:inquiry])
               [:ok, context]
             end

puts sequence.inspect
puts sequence.interactions.inspect

sequence.call(inquiry: inquiry)
