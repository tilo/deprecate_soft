# frozen_string_literal: true

require "deprecate_soft"

# require 'datadog/statsd'

# require 'redis'
# $redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

module DeprecateSoft
  # Optional: customize how the original method is renamed internally
  #
  # For example, if you deprecate `foo`, this affects what the internal
  # renamed method will be called. These names should be unlikely to conflict.
  #
  # Default is "__" and "deprecated", which becomes: "__foo_deprecated"
  # config.prefix = "__"
  # config.suffix = "deprecated"

  # Optional: set up your tracking solution
  #
  # redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  # statsd = Datadog::Statsd.new

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
end
