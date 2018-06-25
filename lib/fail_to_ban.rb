require 'fail_to_ban/version'
require 'strategies/backoff_strategy'
require 'forwardable'

class FailToBan
  extend ::Forwardable

  def initialize(key:, storage:, strategy: Strategies::BackoffStrategy, config: {})
    @strategy = strategy.new(key: key, storage: storage, config: config)
  end

  def_delegators :@strategy, :attempt, :blocked?, :reset, :unlock_at

  def unlock_in
    unlock_at - Time.now.to_i
  end
end
