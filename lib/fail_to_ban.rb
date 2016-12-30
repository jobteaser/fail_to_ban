require "fail_to_ban/version"

class FailToBan

  PROTECT_DURATION = 60 * 60 * 24 # eq 24 hours in seconds

  PERMIT_FAIL_ATTEMPS = 3

  JITTER_VARIANCE = 0.2
  BACKOFF_RATE = 15 # seconds

  attr_reader(:unique_key)

  def initialize(storage:, unique_key:)
    @storage = storage
    @unique_key = unique_key
    @id = "fail_to_ban:#{@unique_key}"
  end

  def protect
    return :blocked if blocked?
    increment_fail_attempts
    :ok
  end

  def blocked?
    return false if retry_count < PERMIT_FAIL_ATTEMPS || Time.now.to_i >= unlock_at
    true
  end

  def reset
    @storage.del(id)
    :ok
  end

  def unlock_at
    @storage.hget(id, 'unlock_at').to_i
  end

  private

  attr_reader(:id)

  def increment_fail_attempts
    @storage.hincrby(id, 'retry_count', 1)
    @storage.hset(id, 'unlock_at', Time.now.to_i + backoff)
    @storage.expire(id, PROTECT_DURATION)
  end

  def retry_count
    @storage.hget(id, 'retry_count').to_i
  end

  # Backoff : after 3 failed attempts there is a 15 seconds wait
  # If it fails again then it's 30 seconds, then 45,
  # In any case, set a +/- 10% jitter on the wait (e.g 14, 28, 47, ...)
  def backoff
    BACKOFF_RATE * (retry_count - PERMIT_FAIL_ATTEMPS) * (1 + JITTER_VARIANCE * (rand - 0.5))
  end

end
