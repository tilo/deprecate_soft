# frozen_string_literal: true

require "spec_helper"
require "deprecate_soft"
require 'date'
require "redis"

RSpec.describe "DeprecateSoft with Redis tracking" do
  let(:mock_redis) { instance_double(Redis) }

  before do
    allow(mock_redis).to receive(:incr)

    DeprecateSoft.configure do |config|
      config.before_hook = lambda do |method, message, args:|
        # Replace # with : for Redis
        redis_key = "deprecate_soft:#{method}".gsub('#', ':')
        mock_redis.incr("#{redis_key}:#{Date.today}")
      end

      config.after_hook = nil
    end
  end

  before do
    stub_const("Klass", Class.new do
      include DeprecateSoft

      def foo(a)
        "x#{a}"
      end

      deprecate_soft :foo, "migrate to #future"
    end)
  end

  it "increments the redis key on call" do
    Klass.new.foo("42")

    expected_key = "deprecate_soft:Klass:foo:#{Date.today}"
    expect(mock_redis).to have_received(:incr).with(expected_key)
  end
end
