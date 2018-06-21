require 'fail_to_ban/version'

class FailToBan
  PROTECT_DURATION = 60 * 60 * 24 # eq 24 hours in seconds

  JITTER_VARIANCE = 0.2

  attr_reader(:unique_key)

  def initialize(storage:, unique_key:, config: {})
    @storage = storage
    @unique_key = unique_key
    @config = default_config.merge(config)
    @id = "fail_to_ban:#{@unique_key}"
  end

  def default_config
    {
      permitted_attempts: 3,
      backoff_step: 15, # in seconds
      backoff_cap: nil
    }
  end

  def protect
    warn '[DEPRECATION] `protect` is deprecated.  Please use `attempt` instead.'
    attempt
  end

  def attempt
    return :blocked if blocked?
    increment_fail_attempts
    puts backoff
    :ok
  end

  def blocked?
    return false if retry_count < @config[:permitted_attempts] || Time.now.to_i >= unlock_at
    true
  end

  def reset
    @storage.del(id)
    :ok
  end

  def unlock_at
    @storage.hget(id, 'unlock_at').to_i
  end

  def unlock_in
    unlock_at - Time.now.to_i
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

  # Backoff : after the permitted_attempts is exceeded is a x seconds wait
  # If it fails again then it's x * 2 seconds, then x * 3,
  # If the back_time exceeds the backoff cap, then it stop growing
  # In any case, set a +/- 10% jitter on the wait (e.g with a backoff step of 15: 14, 28, 47, ...)
  def backoff
    variance = (1 + JITTER_VARIANCE * (rand - 0.5))
    back_time = @config[:backoff_step] * (retry_count - @config[:permitted_attempts] + 1) * variance
    if !@config[:backoff_cap].nil? && back_time > @config[:backoff_cap] * variance
      @config[:backoff_cap] * variance
    else
      back_time
    end
  end

end
