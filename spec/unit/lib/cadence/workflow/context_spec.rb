require 'cadence/testing/local_workflow_context'
require 'cadence/workflow/context'
require 'cadence/workflow/dispatcher'
require 'cadence/configuration'
require 'cadence/metadata/workflow'

class MyTestWorkflow < Cadence::Workflow; end

describe Cadence::Workflow::Context do
  subject { described_class.new(state_manager, dispatcher, metadata, config, query_registry) }

  let(:state_manager) { instance_double('Cadence::Workflow::StateManager') }
  let(:dispatcher) { Cadence::Workflow::Dispatcher.new }
  let(:metadata_hash) do
    {
      domain: 'test-domain',
      id: SecureRandom.uuid,
      name: 'TestWorkflow',
      run_id: SecureRandom.uuid,
      attempt: 0,
      timeouts: { execution: 15, task: 10 },
      headers: { 'TestHeader' => 'Value' }
    }
  end
  let(:metadata) { Cadence::Metadata::Workflow.new(metadata_hash) }
  let(:config) { Cadence::Configuration.new }
  let(:query_registry) { instance_double('Cadence::Workflow::QueryRegistry') }
  let(:workflow_context) do
    Cadence::Workflow::Context.new(
      state_manager,
      dispatcher,
      metadata,
      Cadence.configuration,
      query_registry,
    )
  end

  describe '#on_query' do
    let(:handler) { Proc.new {} }

    before { allow(query_registry).to receive(:register) }

    it 'registers a query with the query registry' do
      workflow_context.on_query('test-query', &handler)

      expect(query_registry).to have_received(:register).with('test-query') do |&block|
        expect(block).to eq(handler)
      end
    end
  end

  describe '#headers' do
    it 'returns metadata headers' do
      expect(workflow_context.headers).to eq('TestHeader' => 'Value')
    end
  end

  describe '.sleep_until' do
    let(:start_time) { Time.now }
    let(:end_time) { Time.now + 1 }
    let(:delay_time) { (end_time - start_time).to_i }

    before do
      allow(state_manager).to receive(:local_time).and_return(start_time)
      allow(subject).to receive(:sleep)
    end

    it 'sleeps until the given end_time' do
      subject.sleep_until(end_time)
      # Since sleep_until uses, sleep, just make sure that sleep is called with the delay_time
      expect(subject).to have_received(:sleep).with(delay_time)
    end
  end
end
