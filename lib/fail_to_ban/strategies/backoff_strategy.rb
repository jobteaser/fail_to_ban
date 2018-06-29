class FailToBan
  module Strategies
    class BackoffStrategy

      PROTECT_DURATION = 60 * 60 * 24 # eq 24 hours in seconds
      private_constant :PROTECT_DURATION

      JITTER_VARIANCE = 0.2
      private_constant :JITTER_VARIANCE

      HEADER = 'fail_to_ban'.freeze
      private_constant :HEADER

      def initialize(key:, storage:, config: {})
        @storage = storage
        @config = default_config.merge(config)
        @id = "#{HEADER}:#{key}"
      end

      def call
        true
      end

      def attempt
        return :blocked if blocked?
        increment_failed_attempts
        :ok
      end

      def blocked?
        retry_count >= @config[:permitted_attempts] && Time.now.to_i < unlock_at
      end

      def reset
        @storage.del(@id)
      end

      def unlock_at
        @storage.hget(@id, 'unlock_at').to_i
      end

      private

      def default_config
        {
          permitted_attempts: 3,
          backoff_step: 15, # in seconds
          backoff_cap: nil
        }
      end

      def increment_failed_attempts
        @storage.hincrby(@id, 'retry_count', 1)
        @storage.hset(@id, 'unlock_at', Time.now.to_i + backoff)
        @storage.expire(@id, PROTECT_DURATION)
      end

      def retry_count
        @storage.hget(@id, 'retry_count').to_i
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
  end
end
