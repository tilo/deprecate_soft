# frozen_string_literal: true

require 'spec_helper'
require 'deprecate_soft'
require 'date'
require 'redis'

RSpec.describe 'DeprecateSoft with Redis tracking' do
  let(:mock_redis) { instance_double(Redis) }
  let(:klass) do
    Class.new do
      include DeprecateSoft

      def foo(a)
        "x#{a}"
      end

      def self.name
        'TestKlass' # for string formatting in the wrapper
      end

      soft_deprecate :foo, 'will be deleted'
    end
  end

  before do
    allow(mock_redis).to receive(:incr)

    DeprecateSoft.configure do |config|
      config.before_hook = lambda do |method, _message, args:|
        redis_key = "deprecate_soft:#{method}".gsub('#', ':')
        mock_redis.incr("#{redis_key}:#{Date.today}")
      end

      config.after_hook = nil
    end
  end

  it 'increments the redis key on call' do
    klass.new.foo('42')

    expected_key = "deprecate_soft:TestKlass.foo:#{Date.today}"
    expect(mock_redis).to have_received(:incr).with(expected_key)
  end
end
