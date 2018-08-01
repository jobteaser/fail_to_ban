# FailToBan

[![Build Status](https://travis-ci.org/jobteaser/fail_to_ban.svg?branch=master)](https://travis-ci.org/jobteaser/fail_to_ban)
[![Code Climate](https://codeclimate.com/repos/58667ffceab18f66d7000836/badges/86fb76a0e71dd832bdea/gpa.svg)](https://codeclimate.com/repos/58667ffceab18f66d7000836/feed)
![Dependencies](https://img.shields.io/badge/dependencies-none-green.svg)

Handle brute force on key backed by Redis.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fail_to_ban', git: 'https://github.com/jobteaser/fail_to_ban.git', tag: 'v0.2.1'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fail_to_ban

## Usage

We provide a default backoff strategy, see: [backoff_strategy.rb](lib/fail_to_ban/strategies/backoff_strategy.rb)

You can make your own custom strategy and inject it, your strategy will be initialized with the following parameters: `key`, `storage`, `config`

The following methods should be implemented:

|Name     |Type   |Description|
|---------|-------|-----------|
|attempt  |symbol |Make a connection attempt, could increment a retry_count for example.|
|blocked? |boolean|Should Tell wether the key should be blocked for another attempt.        |
|reset    |symbol |Should remove the key in storage.                            |
|unlock_at|Time   |Should return the time when the lock will be lifted.                     |

```ruby
$redis = Redis.new

FailToBan.new(
  key: 'hello/42', # Can be any string, should be unique
  storage: $redis, # A key value storage compatible with the redis api
  strategy: Strategies::BackoffStrategy, # Optionnal
  config: { permitted_attempts: 3, backoff_step: 15 } # Optionnal
)
```

### An example with the default `BackoffStrategy`

#### Config parameters

|Parameter         |Type   |Description|Default|
|------------------|-------|-----------|-------|
|permitted_attempts|Integer|The number of permitted attemps before locking the key.|3|
|backoff_step      |Integer|The time the key will be locked for, in seconds, and incrementing after every fail.|15|
|backoff_cap       |Integer|The time after which the unlock_at will stop being incremented. (nil = no limit)|nil|

```ruby

$redis = Redis.new

FailToBan.new(
  key: 'dev@jobteaser.com',
  storage: $redis,
  strategy: Strategies::BackoffStrategy, # By default
  config: { permitted_attempts: 3, backoff_step: 15 }
)

protection.blocked?
# => false

protection.attempt
# => :ok

# Backoff : after 3 failed attempts there is a 15 seconds wait
# If it fails again then it's 30 seconds, then 45,
# In any case, set a +/- 10% jitter on the wait (e.g 14, 28, 47, ...)
protection.attempt
# => :blocked

# this method reset blocked key
protection.reset
# => :ok

# this method returns ETA when account
# will be unblocked
protection.unlock_at
# => timestamp

# this method returns the time left before
# the account will be unblocked
protection.unlock_at
# => timestamp

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jobteaser/fail_to_ban. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
