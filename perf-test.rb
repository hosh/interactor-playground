require 'active_support'
require 'rlet'
require 'functional_interactor'
require 'kase'
require 'map'
require 'ap'
require 'benchmark'

N = 10000

class FunctionalNoOp
  include FunctionalInteractor

  def call(context={})
    [:ok, context]
  end
end

class FunctionalFailureOp
  include FunctionalInteractor

  def call(context={})
    [:error, :error]
  end
end

# Equivalent code:
# functional_interaction = FunctionalNoOp | FunctionalNoOp | FunctionalNoOp ...
def functional_interactions
  (1..9).to_a.inject(FunctionalNoOp) { |interaction, _| interaction | FunctionalNoOp }
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

def functional_interactions_0
  FunctionalNoOp | FunctionalNoOp
end

def functional_failure_0
  FunctionalNoOp | FunctionalFailureOp
end

class FunctionalController
  def self.successful_action(simple:)
    interactions = simple ? functional_interactions_0 : functional_interactions
    Kase.kase interactions.call do
      on(:ok)    { |context| context }
      on(:error) { |reason| report_error(reason) }
    end
  end

  def self.failing_action(simple:)
    interactions = simple ? functional_failure_0 : functional_failure
    Kase.kase interactions.call do
      on(:ok)    { |context| context }
      on(:error) { |reason| report_error(reason) }
    end
  end

  def self.report_error(reason)
    reason
  end
end

class NoOpInteractor
  include Interactor

  def call
  end
end

class FailureInteractor
  include Interactor

  def call
    context.fail!(error: :error)
  end
end

class SimpleNoOpOrganizer
  include Interactor::Organizer
  organize NoOpInteractor, NoOpInteractor
end

class NoOpOrganizer
  include Interactor::Organizer
  organize NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor
end

class SimpleFailureOrganizer
  include Interactor::Organizer
  organize NoOpInteractor, FailureInteractor
end

class FailureOrganizer
  include Interactor::Organizer
  organize NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, FailureInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor, NoOpInteractor
end

class OOPController
  def self.successful_action(simple:)
    interactor = simple ? SimpleNoOpOrganizer : NoOpOrganizer
    result = interactor.call
    report_error(result.error) unless result.success?
  end

  def self.failing_action(simple:)
    interactor = simple ? SimpleFailureOrganizer : FailureOrganizer
    result = interactor.call
    report_error(result.error) unless result.success?
  end

  def self.report_error(reason)
    reason
  end
end


puts "N = #{N}"
# Tries to minimize garbage collection effects
# http://ruby-doc.org/stdlib-2.3.0/libdoc/benchmark/rdoc/Benchmark.html#method-c-bmbm
Benchmark.bmbm(27) do |x|
  x.report('collective_idea x2')         { N.times { OOPController.successful_action(simple: true) } }
  x.report('functional x2')              { N.times { FunctionalController.successful_action(simple: true) } }
  x.report('collective_idea x10')        { N.times { OOPController.successful_action(simple: false) } }
  x.report('functional x10')             { N.times { FunctionalController.successful_action(simple: false) } }
  x.report('collective_idea [fail] x2')  { N.times { OOPController.failing_action(simple: false) } }
  x.report('functional [fail] x2')       { N.times { FunctionalController.failing_action(simple: false) } }
  x.report('collective_idea [fail] x10') { N.times { OOPController.failing_action(simple: false) } }
  x.report('functional [fail] x10')      { N.times { FunctionalController.failing_action(simple: false) } }
end
