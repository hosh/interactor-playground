require 'active_support'
require 'rlet'
require 'functional_interactor'
require 'kase'
require 'map'
require 'ap'
require 'benchmark'

N = 10000

# Simple, naive test

class FunctionalNoOp
  include FunctionalInteractor

  def call(context={})
    [:ok, context]
  end
end

# Equivalent code:
# functional_interaction = FunctionalNoOp | FunctionalNoOp | FunctionalNoOp ...
def functional_interactions
  (1..9).to_a.inject(FunctionalNoOp) { |interaction, _| interaction | FunctionalNoOp }
end

class NoOpInteractor
  include Interactor

  def call
  end
end

class NoOpOrganizer
  include Interactor::Organizer
  organize NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor
end

puts "========"
puts "NoOp interactors chained 10, N=#{N}"
# Tries to minimize garbage collection effects
# http://ruby-doc.org/stdlib-2.3.0/libdoc/benchmark/rdoc/Benchmark.html#method-c-bmbm
Benchmark.bmbm(15) do |x|
  x.report('collective_idea') { N.times { NoOpOrganizer.call } }
  x.report('functional')      { N.times { functional_interactions.call } }
end


puts "========"
puts "NoOp + FailureOp (5th) interactors chained 10, N=#{N}"

class FunctionalFailureOp
  include FunctionalInteractor

  def call(context={})
    [:error, :error]
  end
end

def functional_failure
  FunctionalNoOp \
  | FunctionalNoOp \
  | FunctionalNoOp \
  | FunctionalNoOp \
  | FunctionalFailureOp \
  | FunctionalNoOp \
  | FunctionalNoOp \
  | FunctionalNoOp \
  | FunctionalNoOp \
  | FunctionalNoOp
end

class FunctionalController
  def self.action
    Kase.kase functional_failure.call do
      on(:ok)    { |context| context }
      on(:error) { |reason| report_error(reason) }
    end
  end

  def self.report_error(reason)
    reason
  end
end

class FailureInteractor
  include Interactor

  def call
    context.fail!(error: :error)
  end
end

class FailureOrganizer
  include Interactor::Organizer
  organize NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, FailureInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor
end

class OOPController
  def self.action
    result = FailureOrganizer.call
    report_error(result.error) unless result.success?
  end

  def self.report_error(reason)
    reason
  end
end

Benchmark.bmbm(15) do |x|
  x.report('collective_idea') { N.times { OOPController.action } }
  x.report('functional')      { N.times { FunctionalController.action } }
end
