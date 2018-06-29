require 'spec_helper'

class NullStorage

  def initialize(null_data = {})
    @null_data = null_data
  end

  def hset(k, hk, hv)
    @null_data[k] ||= {}
    @null_data[k][hk] = hv.to_s
  rescue NoMethodError
    nil
  end

  def hincrby(k, hk, i)
    @null_data[k] ||= {}
    @null_data[k][hk] = @null_data[k][hk].to_i + i
  end

  def hget(k, hk)
    @null_data[k][hk]
  rescue NoMethodError
    nil
  end

  def expire(k, t)
    nil
  end

  def del(k)
    @null_data.delete(k)
  end

end

RSpec.describe FailToBan::Strategies::BackoffStrategy do

  it "has a version number" do
    expect(FailToBan::VERSION).not_to be nil
  end

  let(:storage) { NullStorage.new(data) }

  describe '#attempt' do
    subject do
      FailToBan.new(
        key: key,
        storage: storage,
        strategy: described_class,
        config: { permitted_attempts: 3, backoff_step: 15 }
      )
    end

    let(:key) { 'dev@jobteaser.com' }
    let(:data) { {} }

    it 'increments retry_count' do
      expect { subject.attempt }.to change {
        storage.hget("fail_to_ban:#{key}", 'retry_count')
      }.from(nil).to(1)
    end

    it 'returns :ok' do
      expect(subject.attempt).to be :ok
    end

    context 'when retry exceeds the permitted_attempts' do
      let(:data) { {} }

      it 'returns :blocked' do
        allow(Time).to receive(:now).and_return(Time.new('2015', '01', '01'))

        3.times { expect(subject.attempt).to eq :ok }
        expect(subject.attempt).to eq :blocked
      end
    end

    context 'when unlock_at have expired' do
      let(:data) do
        { "fail_to_ban:#{key}" => { 'retry_count' => '5', 'unlock_at' => Time.new('2014', '12', '12').to_i.to_s } }
      end

      it 'returns :ok' do
        allow(Time).to receive(:now).and_return(Time.new('2015', '01', '01'))
        expect(subject.attempt).to eq :ok
      end
    end
  end

  describe '#blocked?' do
    subject do
      FailToBan.new(
        key: key,
        storage: storage,
        strategy: described_class
      )
    end

    let(:key) { 'dev@jobteaser.com' }

    context 'when key is not blocked' do
      let(:data) { {} }

      it 'returns false' do
        expect(subject.blocked?).to be false
      end
    end

    context 'when key is blocked' do
      let(:data) do
        { "fail_to_ban:#{key}" => {"retry_count" => "4", "unlock_at" => " 1477401039" }  }
      end

      it 'returns true' do
        allow(Time).to receive(:now).and_return(Time.new('2015', '01', '01'))
        expect(subject.blocked?).to be true
      end
    end
  end

  describe '#reset' do
    subject do
      FailToBan.new(
        key: key,
        storage: storage,
        strategy: described_class
      )
    end

    let(:key) { 'dev@jobteaser.com' }
    let(:data) do
      { "fail_to_ban:#{key}" => { 'retry_count' => '0', 'unlock_at' => '0' } }
    end

    it 'removes retry_count from storage' do
      expect { subject.reset }.to change { storage.hget("fail_to_ban:#{key}", 'retry_count') }.from('0').to(nil)
    end

    it 'removes unlock_at from storage' do
      expect { subject.reset }.to change { storage.hget("fail_to_ban:#{key}", 'unlock_at') }.from('0').to(nil)
    end
  end

end
