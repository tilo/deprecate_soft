
# DeprecateSoft

**DeprecateSoft** is a light-weight and flexible Ruby gem that helps you gracefully and safely deprecate methods. 

Instead of immediately removing or raising on deprecated methods, this gem allows you to wrap existing methods with before/after hooks — ideal for tracking usage across your application via logs, Redis, DataDog, or any other tool.

Once you verify in the tracking that the method is no longer used, you can safely delete it from your code.

---

## ✨ Features

- Lightweight method wrapper for deprecation tracking
- Works with instance methods in any class or module
- Works with class or module methods in any class or module
- System-wide hook configuration (before and after)
- No monkey-patching or global pollution
- Fully compatible with Rails or plain Ruby apps

---

## 🚀 Installation

Add this to your Gemfile:

```ruby
gem 'deprecate_soft', path: 'path/to/your/local/gem'
```

Then run:

```sh
bundle install
```

---

## ⚙️ Configuration

Create an initializer in your Rails app (or load manually in a non-Rails project):

```ruby
# config/initializers/deprecate_soft.rb

require "deprecate_soft"

# Optional: require Redis or DataDog as needed
# require "redis"
# require "datadog/statsd"

module DeprecateSoft
  # Optional: scoped setup (not global!)
  #
  # redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  # statsd = Datadog::Statsd.new

  configure do |config|
    config.before_hook = lambda do |method, message, args:|
      # Log
      # Rails.logger.warn "DEPRECATED: #{method} : #{message}"

      # Redis example:
      # redis_key = "deprecate_soft:#{method.gsub('#', ':')}"
      # redis.incr("#{redis_key}:#{Date.today}")

      # DataDog example:
      # metric_name = "deprecate_soft.#{method.tr('#', '.').downcase}"
      # statsd.increment(metric_name)
    end

    # Optional after hook
    # config.after_hook = lambda do |method, message, result:|
    #   puts "Deprecated method #{method} finished execution"
    # end
  end
end
```

This setup ensures you can plug in **any tracking backend** you like — without polluting the global namespace.

---

## 🧩 Usage


### For Instance Methods:

```ruby
class MyService
  include DeprecateSoft

  def legacy_method(a, b)
    puts "doing something with #{a} and #{b}"
  end

  deprecate_soft :legacy_method, "Use #new_method instead"
end

MyService.new.legacy_method(1, 2) # will exercise the tracking hooks
```

### For Class Methods:

```ruby
class MyService
  extend DeprecateSoft

  def self.legacy_method(a, b)
    puts "doing something with #{a} and #{b}"
  end

  deprecate_soft :legacy_method, "Use #new_method instead"
end

MyService.legacy_method(1, 2) # will exercise the tracking hooks

```

---

## 🔐 What It Does Under the Hood

When you call `deprecate_soft :method_name, "reason"`:

1. It renames the original method to `__method_name_original`.
2. It defines a new method with the original name that:
   - Calls the configured `before_hook` (if set)
   - Delegates to the original method
   - Calls the configured `after_hook` (if set)
3. The renamed method is made private to discourage direct use.

This ensures consistent tracking, clean method resolution, and avoids accidental bypassing.

---

## 🧪 Example Hook Logic

You can track usage using whatever backend you like. Here are some quick examples:

### Redis:

```ruby
config.before_hook = lambda do |method, message, args:|
  redis_key = "deprecate_soft:#{method.gsub('#', ':')}"
  redis.incr("#{redis_key}:#{Date.today}")
end
```

### DataDog:

```ruby
config.before_hook = lambda do |method, message, args:|
  metric_name = "deprecate_soft.#{method.tr('#', '.').downcase}"
  statsd.increment(metric_name)
end
```

### Log only:

```ruby
config.before_hook = ->(method, message, args:) {
  Rails.logger.warn "DEPRECATED: #{method} - #{message}"
}
```

---

## 🛡 Best Practices

- Only use for methods you plan to remove but want to measure first.
- Integrate with your observability platform for tracking.
- Review usage stats before deleting deprecated methods.

---

## 🧰 Limitations / Notes

- Make sure hooks do not raise or interfere with production behavior.
- Currently assumes Ruby 2.5+ (for `&.` and keyword args support).

---

## 📬 Contributing

Feel free to open issues or pull requests if you'd like to:

- Add support for class methods
- Add Railtie for automatic setup
- Add built-in backends (e.g. Redis, StatsD)

---

## 📜 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

## 💡 Inspiration

Inspired by the need to track deprecated method usage in large codebases before safely removing them, with zero disruption and flexible metrics support.
