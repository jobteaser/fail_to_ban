require "spec_helper"

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

describe FailToBan do

  it "has a version number" do
    expect(FailToBan::VERSION).not_to be nil
  end

  let(:storage) { NullStorage.new(data) }

  describe '#protect' do

    subject { described_class.new(storage: storage, unique_key: key).protect }

    let(:key) { 'dev@jobteaser.com' }

    context 'when retry < 3' do

      let(:data) do
        {}
      end

      it 'increments retry_count' do
        expect { subject }.to change { storage.hget("fail_to_ban:#{key}", "retry_count") }.from(nil).to(1)
      end

      it 'returns :ok' do
        expect(subject).to be :ok
      end

    end

    context 'when retry > 3' do
      let(:data) do
        {}
      end

      it 'returns :blocked' do
        allow(Time).to receive(:now).and_return(Time.new('2015', '01', '01'))
        foo = described_class.new(storage: storage, unique_key: key)

        described_class::PERMIT_FAIL_ATTEMPS.times do
          expect(foo.protect).to eq :ok
        end
        expect(foo.protect).to eq :blocked
      end

    end

    context 'when unlock_at have expire' do

      let(:data) do
        { "fail_to_ban:#{key}" => { "retry_count" => "5", "unlock_at" => Time.new('2014', '12', '12').to_i.to_s } }
      end

      it 'returns :ok' do
        allow(Time).to receive(:now).and_return(Time.new('2015', '01', '01'))
        expect(subject).to eq :ok
      end

    end

  end

  describe '#blocked?' do

    subject { described_class.new(storage: storage, unique_key: key).blocked? }

    let(:key) { 'dev@jobteaser.com' }

    context 'when key is not blocked' do

      let(:data) do
        {}
      end

      it 'returns false' do
        expect(subject).to be false
      end

    end

    context 'when key is blocked' do

      let(:data) do
        { "fail_to_ban:#{key}" => {"retry_count" => "4", "unlock_at" => " 1477401039" }  }
      end

      it 'returns true' do
        allow(Time).to receive(:now).and_return(Time.new('2015', '01', '01'))
        expect(subject).to be true
      end

    end

  end

  describe '#reset!' do

    subject { described_class.new(storage: storage, unique_key: key).reset }

    let(:key) { 'dev@jobteaser.com' }

    let(:data) do
      { "fail_to_ban:#{key}" => { "retry_count" => "0", "unlock_at" => "0" } }
    end

    it 'removes retry_count from storage' do
      expect { subject }.to change { storage.hget("fail_to_ban:#{key}", "retry_count") }.from('0').to(nil)
    end

    it 'removes unlock_at from storage' do
      expect { subject }.to change { storage.hget("fail_to_ban:#{key}", "unlock_at") }.from('0').to(nil)
    end

  end

end
