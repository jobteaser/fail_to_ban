# FailToBan

[![Build Status](https://travis-ci.org/jobteaser/fail_to_ban.svg?branch=master)](https://travis-ci.org/jobteaser/fail_to_ban)
[![Code Climate](https://codeclimate.com/repos/58667ffceab18f66d7000836/badges/86fb76a0e71dd832bdea/gpa.svg)](https://codeclimate.com/repos/58667ffceab18f66d7000836/feed)
![Dependencies](https://img.shields.io/badge/dependencies-none-green.svg)

Handle brute force on key backed by Redis.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fail_to_ban', git: 'https://github.com/jobteaser/fail_to_ban.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fail_to_ban

## Usage

|parameter|description|type|default|
|---------|-----------|----|-------|
|permitted_attempts|The number of authorized attempts before being blocked.|integer|3
|backoff_step|The amount of time to wait that will be added after every locking (in seconds).|integer|15
|backoff_cap|The amount of backoff time after wich the backoff time stop increasing (in seconds).|integer|nil

```ruby

$redis = Redis.new

protection = FailToBan.new(
  storage: $redis,
  unique_key: 'dev@jobteaser.com',
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

# this methdod return ETA when account
# will be unlocked
protection.unlock_at
# => timestamp

# this methdod return the estimated time the
# account will be locked
protection.unlock_in
# => time in seconds

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jobteaser/fail_to_ban. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
