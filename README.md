# FailToBan

[![Build Status](https://travis-ci.org/jobteaser/fail_to_ban.svg?branch=master)](https://travis-ci.org/jobteaser/fail_to_ban)

Handle brute force on key backed by Redis.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fail_to_ban', git: 'https://github.com/jobteaser/fail_to_ban.git', tag: 'v0.1.1'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fail_to_ban

## Usage

```ruby

$redis = Redis.new

protection = FailToBan.new(storage: $redis, unique_key: "dev@jobteaser.com")
protection.block?
# => false

protection.protect
# => :ok

# this method increment fail
# after 3 attempts key is blocked
# 30 seconds

protection.protect
# => :blocked

# this method reset blocked key
protection.reset
# => :ok

# this methdod return ETA when account
# was unblock
protection.unlock_at
# => timestamp

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jobteaser/fail_to_ban. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

