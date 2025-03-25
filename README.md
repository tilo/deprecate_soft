
# DeprecateSoft

DeprecateSoft is a lightweight and flexible Ruby gem designed to help you gracefully and safely delete methods.

It was inspired by the need to track deprecated method usage in large codebases before safely removing old code — with zero disruption and flexible metrics support.

This gem lets you wrap existing methods with before and after hooks to track usage patterns without changing the method's behavior, and without any impact on production systems.

It’s ideal for monitoring deprecated method usage across your application using non-blocking, low-latency tools such as Redis, DataDog, Prometheus, or logs.

Once tracking confirms that a deprecated method is no longer in use, you can confidently delete it from your codebase.

This mechanism has been **proven in large-scale production systems** to safely clean up legacy code — this gem reimagines that functionality to help you clean up your code with confidence.

---

## ✨ Features

- Lightweight method wrapper for deprecation tracking
- Works with instance methods in any class or module
- Works with class or module methods in any class or module
- System-wide hook configuration (before and after)
- No monkey-patching or global pollution — unless you explicitly opt in via `GlobalMonkeyPatch`
- Fully compatible with Rails or plain Ruby apps

---

## 🚀 Installation

Add this to your Gemfile:

```ruby
gem 'deprecate_soft'
```

Then run:

```sh
bundle install
```

---

## ⚙️ Configuration

Create an initializer in your Rails app (or load manually in a non-Rails project):

```ruby
# frozen_string_literal: true

require "deprecate_soft"

# Optional: set up your tracking solution

# require 'redis'
# redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

# require 'datadog/statsd'
# statsd = Datadog::Statsd.new

DeprecateSoft.configure do |config|
  # Required: define a before_hook to track method usage
  #
  # You can use Redis, StatsD, DataDog, Prometheus, etc.
  config.before_hook = lambda do |method, message, args:|
    # Track via Redis:
    # redis_key = "deprecate_soft:#{method.gsub('#', ':')}"
    # redis.incr("#{redis_key}")
    # or:
    # redis.incr("#{redis_key}:#{Date.today.cweek}") # weekly count

    # Track via DataDog (StatsD):
    # metric_name = "deprecate_soft.#{method.tr('#', '.').downcase}"
    # statsd.increment(metric_name)

    # Or just log it:
    # Rails.logger.warn "DEPRECATED: #{method} – #{message}"
  end

  # Optional: define an after_hook for additional metrics/logging
  #
  # config.after_hook = lambda do |method, message, result:|
  #   # Optional: Logging or more metrics
  #   puts "[DD] #{method} completed after deprecated call"
  # end

  # Optional: customize how the original method is renamed internally
  #
  # For example, if you deprecate `foo`, this affects what the internal
  # renamed method will be called. These names should be unlikely to conflict.
  #
  # Default is "__" and "deprecated", which becomes: "__foo_deprecated"
  # config.prefix = "__"
  # config.suffix = "deprecated"
end
```

This setup ensures you can plug in **any tracking backend** you like — without polluting the global namespace.

### 🔧 Customizing Method Name Wrapping

When `deprecate_soft` wraps a method, it renames the original method internally to preserve its behavior. You can customize how that internal method is named by configuring a `prefix` and `suffix`.

By default, the original method:

```ruby
def foo
end

deprecate_soft :foo, "Use #bar instead"
```

...will be renamed to:

```ruby
__foo_deprecated
```

You can change the naming convention:

```ruby
DeprecateSoft.configure do |config|
  config.prefix = "legacy_"   # or "" to disable
  config.suffix = "old"       # or nil to disable
end
```

This gives you full control over how deprecated methods are renamed internally.

#### 📝 Naming Examples

| Prefix      | Suffix       | Method Name   | Hidden Method Name        |
|-------------|--------------|---------------|----------------------------|
| `"__"`      | `"deprecated"` | `foo`         | `__foo_deprecated`        |
| `""`        | `"old"`        | `foo`         | `foo_old`                 |
| `"legacy_"` | `""`           | `foo`         | `legacy_foo`              |
| `"_"`       | `"__"`         | `foo`         | `_foo__`                  |

These names are never called directly — they're used internally to wrap and preserve the original method logic.


---

## 🧩 Usage

🚨 Always declare `deprecate_soft` **after** the method definition!

### For Instance Methods:

```ruby
class MyService
  include DeprecateSoft

  def deprecated_method(a, b)
    puts "doing something with #{a} and #{b}"
  end

  deprecate_soft :deprecated_method, "Use #new_method instead"
end

MyService.new.deprecated_method(1, 2) # will exercise the tracking hooks
```

### For Class Methods:

```ruby
class MyService
  extend DeprecateSoft

  def self.deprecated_method(a, b)
    puts "doing something with #{a} and #{b}"
  end

  deprecate_soft :deprecated_method, "will be removed"
end

MyService.deprecated_method(1, 2) # will exercise the tracking hooks

```

---

## 🔐 What It Does Under the Hood

When you call `deprecate_soft :method_name, "reason"`:

1. It renames the original method to `__method_name_deprecated`.
2. It defines a new method with the original name that:
   - Calls the configured `before_hook` (if set)
   - Delegates to the original method
   - Calls the configured `after_hook` (if set)
3. The optional `message` with the reason can help identifying alternatives.

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

## 🧪🧪🧪 Advaned Hook with Caller Tracking:

You can also track callers, so you can identify where you still have to fix your source code:


### Redis:

```ruby
# config/initializers/deprecate_soft.rb

require "deprecate_soft"
require 'redis'

# Configure your redis client instance
redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

DeprecateSoft.configure do |config|
  config.before_hook = lambda do |method, message, args:|
    # Get the direct caller of the deprecated method
    caller_info = caller_locations(1, 1).first

    caller_key = if caller_info
      "#{caller_info.path}:#{caller_info.lineno}"
    else
      "unknown"
    end

    # Track a global usage counter
    redis.incr("deprecate_soft:#{method}")

    # Track usage by caller location
    redis.incr("deprecate_soft:#{method}:caller:#{caller_key}")

    # Log the usage by caller location
    Rails.logger.info("Deprecated #{method} called from #{caller_key}")
  end
end
```

If `Klass#legacy_method` is called from `app/services/foo.rb:42`, and `app/jobs/cleanup_job.rb:88`, you get:

```
Klass#legacy_method → 7
Klass#legacy_method:caller:app/services/foo.rb:42 → 3
Klass#legacy_method:caller:app/jobs/cleanup_job.rb:88 → 4
```

💡 Now you not only know that the method is still used -- you know where from, and how often -- so you can fix your code.

--- 

## 💪 Optional: Global Monkey Patching

For large projects, it can be beneficial to enable deprecate_soft across the entire codebase without having to explicitly `include DeprecateSoft` or e`xtend DeprecateSoft` in each class or module.

To do this, you can globally monkey-patch `Module` by including `DeprecateSoft::GlobalMonkeyPatch`. This is **entirely optional and not enabled by default**.

Add the following to your `config/initializers/deprecate_soft.rb` initializer:

```ruby
# config/initializers/deprecate_soft.rb

require "deprecate_soft"
require "deprecate_soft/global_monkey_patch"

# ... 

class Module
  include DeprecateSoft::GlobalMonkeyPatch
end

DeprecateSoft.configure do |config|
  #
  # ...  
  #
end

```

---

## 🛡 Best Practices

- Use `deprecate_soft` for methods you plan to remove but want to confirm they are no longer used.
- Integrate with your observability platform for tracking.
- Review usage stats before deleting deprecated methods from your code.
- 🚨 Always declare `deprecate_soft` **after** the method definition! 🚨

---

## 🧰 Limitations / Notes

- Make sure hooks do not raise or interfere with production behavior.
- Only use non-blocking, low-latency methods for tracking!
- Currently assumes Ruby 2.5+ (for `&.` and keyword args support).
- Currently keeps the visibility of the renamed original method the same (does not make it private).

---

## 📬 Contributing

Feel free to open issues or pull requests if you'd like to:

- Add support for class methods
- Add Railtie for automatic setup
- Add built-in backends (e.g. Redis, StatsD)

---

## 📜 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
