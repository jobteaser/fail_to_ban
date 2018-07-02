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
      allow(Time).to receive(:now).and_return(Time.new('2014', '12', '11').utc)
      expect_any_instance_of(NullStrategy)
        .to receive(:unlock_at)
        .and_return(Time.new('2014', '12', '12').utc)
      expect(subject.unlock_in).to eq(24 * 60 * 60) # 1 day in seconds
    end
  end

  it 'has a version number' do
    expect(FailToBan::VERSION).not_to be nil
  end
end
