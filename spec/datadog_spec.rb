# frozen_string_literal: true

require 'spec_helper'
require 'deprecate_soft'
require 'datadog/statsd'

RSpec.describe 'DeprecateSoft with DataDog tracking' do
  let(:mock_statsd) { instance_double(Datadog::Statsd) }

  before do
    allow(mock_statsd).to receive(:increment)

    DeprecateSoft.configure do |config|
      config.before_hook = lambda do |method, _message, args:|
        # Replace # with . for DataDog
        metric_name = "deprecate_soft.#{method.gsub('#', '.')}"
        mock_statsd.increment(metric_name)
      end

      config.after_hook = nil
    end
  end

  before do
    stub_const('Klass', Class.new do
      include DeprecateSoft

      def foo(a)
        "x#{a}"
      end

      deprecate_soft :foo, 'use #bar instead'
    end)
  end

  it 'sends a metric to DataDog with deprecate_soft.Klass.method format' do
    Klass.new.foo('123')

    expect(mock_statsd).to have_received(:increment).with('deprecate_soft.Klass.foo')
  end
end
