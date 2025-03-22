require "deprecate_soft"

# require 'datadog/statsd'

# require 'redis'
# $redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

module DeprecateSoft
  #
  # redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  #
  # statsd = Datadog::Statsd.new

  config.before_hook = lambda do |method, message, args:|
    # Track with Redis:
    #
    # redis_key = "deprecate_soft:#{method.gsub('#', ':')}"
    # redis.incr("#{redis_key}")
    # or:
    # redis.incr("#{redis_key}:#{Date.today}")    # daily count

    # Track with DataDog:
    #
    # metric_name = "deprecate_soft.#{method.tr('#', '.').downcase}"
    # statsd.increment(metric_name)

    # Or just log it:
    #
    # Rails.logger.warn "DEPRECATED: #{method} : #{message}"
  end

  # Optional:
  #
  # config.after_hook = lambda do |method, message, result:|
  #   # Optional: Logging or more metrics
  #   puts "[DD] #{method} completed after deprecated call"
  # end
end
