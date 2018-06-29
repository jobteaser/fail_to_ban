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

  def flushdb
    @null_data.clear
  end

end

RSpec.describe FailToBan::Strategies::BackoffStrategy do

  subject do
    described_class.new(
      key: key,
      storage: storage
    )
  end

  let(:storage) { NullStorage.new }
  let(:key) { 'dev@jobteaser.com' }

  after { storage.flushdb }

  describe '#attempt' do
    it 'checks against the retry count' do
      allow(Time).to receive(:now).and_return(Time.new('2015', '01', '01').utc)

      3.times { expect(subject.attempt).to eq :ok }
      expect(subject.attempt).to eq :blocked
    end

    it 'does not take old locks into account' do
      storage.hset("fail_to_ban:#{key}", 'retry_count', '5')
      storage.hset(
        "fail_to_ban:#{key}",
        'unlock_at',
        Time.new('2014', '12', '12').utc.to_i.to_s
      )

      allow(Time).to receive(:now).and_return(Time.new('2015', '01', '01').utc)
      expect(subject.attempt).to eq :ok
    end

    it 'takes current locks into account' do
      storage.hset("fail_to_ban:#{key}", 'retry_count', '5')
      storage.hset(
        "fail_to_ban:#{key}",
        'unlock_at',
        Time.new('2014', '12', '12').utc.to_i.to_s
      )

      allow(Time).to receive(:now).and_return(Time.new('2014', '12', '11').utc)
      expect(subject.attempt).to eq :blocked
    end
  end

  describe '#blocked?' do
    it 'is not blocked by default' do
      expect(subject.blocked?).to be(false)
    end

    it 'takes current locks into account' do
      storage.hset("fail_to_ban:#{key}", 'retry_count', '4')
      storage.hset(
        "fail_to_ban:#{key}",
        'unlock_at',
        Time.new('2014', '12', '12').utc.to_i.to_s
      )
      allow(Time).to receive(:now).and_return(Time.new('2014', '12', '11').utc)

      expect(subject.blocked?).to be(true)
    end
  end

  describe '#reset' do
    it 'removes the data associated with the key from storage' do
      storage.hset("fail_to_ban:#{key}", 'retry_count', '0')
      storage.hset("fail_to_ban:#{key}", 'unlock_at', '0')

      expect { subject.reset }.
        to change { storage.hget("fail_to_ban:#{key}", 'retry_count') }.
        from('0').to(nil).
        and change { storage.hget("fail_to_ban:#{key}", 'unlock_at') }.
        from('0').to(nil)
    end
  end

end
