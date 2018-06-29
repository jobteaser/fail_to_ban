require 'spec_helper'

class NullStrategy
  def initialize(key:, storage:, config: {}); end
end

RSpec.describe FailToBan do
  subject do
    described_class.new(key: 'boring_key', storage: nil, strategy: NullStrategy)
  end

  describe '#attempt' do
    it 'relies on the strategy' do
      expect_any_instance_of(NullStrategy).to receive(:attempt)
      subject.attempt
    end
  end

  describe '#blocked?' do
    it 'relies on the strategy' do
      expect_any_instance_of(NullStrategy).to receive(:blocked?)
      subject.blocked?
    end
  end

  describe '#reset' do
    it 'relies on the strategy' do
      expect_any_instance_of(NullStrategy).to receive(:reset)
      subject.reset
    end
  end

  describe '#unlock_at' do
    it 'relies on the strategy' do
      expect_any_instance_of(NullStrategy).to receive(:unlock_at)
      subject.unlock_at
    end
  end

  describe '#unlock_in' do
    it 'relies on the strategy' do
      allow(Time).to receive(:now).and_return(27)
      expect_any_instance_of(NullStrategy).to receive(:unlock_at).and_return(69)
      expect(subject.unlock_in).to eq(42)
    end
  end

  it 'has a version number' do
    expect(FailToBan::VERSION).not_to be nil
  end
end
