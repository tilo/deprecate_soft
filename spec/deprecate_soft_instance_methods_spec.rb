# frozen_string_literal: true

require 'spec_helper'
require 'deprecate_soft'

RSpec.describe DeprecateSoft do
  before do
    DeprecateSoft.before_hook = nil
    DeprecateSoft.after_hook = nil
  end

  describe 'deprecate Instance Methods' do
    let(:klass) do
      Class.new do
        include DeprecateSoft

        def hello(name)
          "Hello, #{name}"
        end

        deprecate_soft :hello, 'Use #greet instead'
      end
    end

    it 'returns the original result' do
      expect(klass.new.hello('world')).to eq('Hello, world')
    end

    it 'does not raise if before_hook is nil' do
      DeprecateSoft.before_hook = nil
      expect { klass.new.hello('world') }.not_to raise_error
    end

    it 'calls before_hook if defined' do
      called = nil
      DeprecateSoft.before_hook = lambda do |method, message, args:|
        called = [method, message, args]
      end

      klass.new.hello('foo')

      expect(called[0]).to match(/\.hello/)
      expect(called[1]).to eq('Use #greet instead')
      expect(called[2]).to eq(['foo'])
    end

    it 'does not raise if after_hook is nil' do
      DeprecateSoft.after_hook = nil
      expect { klass.new.hello('world') }.not_to raise_error
    end

    it 'calls after_hook if defined' do
      called = nil
      DeprecateSoft.after_hook = lambda do |method, message, result:|
        called = [method, message, result]
      end

      klass.new.hello('bar')

      expect(called[0]).to match(/\.hello/)
      expect(called[1]).to eq('Use #greet instead')
      expect(called[2]).to eq('Hello, bar')
    end

    it 'wraps private methods too' do
      klass = Class.new do
        include DeprecateSoft

        private

        def hidden; 'shh'; end
        deprecate_soft :hidden, 'to be deleted'

        def call_hidden
          hidden
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.new.send(:call_hidden)).to eq('shh') # method calls are not affected
      expect(called).to be true
    end

    it 'handles multiple deprecations correctly' do
      called = []

      DeprecateSoft.before_hook = lambda do |method, message, args:|
        called << [method, message]
      end

      klass = Class.new do
        include DeprecateSoft

        def foo; :foo; end
        def bar; :bar; end

        deprecate_soft :foo, 'to be deleted'
        deprecate_soft :bar, 'also to be deleted'
      end

      obj = klass.new
      obj.foo
      obj.bar

      expect(called.size).to eq(2)
      expect(called[0][0]).to match(/\.foo/)
      expect(called[1][0]).to match(/\.bar/)
    end

    it 'wraps method even if it is defined after deprecate_soft' do
      klass = Class.new do
        include DeprecateSoft
        deprecate_soft :later_method, 'will be added'
        def later_method
          'defined later'
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.new.later_method).to eq('defined later')
      expect(called).to be true
    end

    it 'does not double-wrap if called twice on same method' do
      klass = Class.new do
        include DeprecateSoft

        def foo; 'foo'; end

        deprecate_soft :foo, 'first warning'
        deprecate_soft :foo, 'second warning' # this will be ignored!
      end

      calls = []
      DeprecateSoft.before_hook = ->(method, message, args:) { calls << message }

      klass.new.foo
      expect(calls).to eq(['first warning']) # or just once
    end

    describe 'when hooks raise an exception' do
      it 'still runs method if before_hook raises' do
        DeprecateSoft.before_hook = ->(*) { raise 'fail!' }

        klass = Class.new do
          include DeprecateSoft
          def hello; 'ok'; end
          deprecate_soft :hello, 'failing hook'
        end

        expect { klass.new.hello }.not_to raise_error('fail!')
        expect(klass.new.hello).to eq 'ok'
      end

      it 'still runs method if after_hook raises' do
        DeprecateSoft.after_hook = ->(*) { raise 'fail!' }

        klass = Class.new do
          include DeprecateSoft
          def hello; 'ok'; end
          deprecate_soft :hello, 'failing hook'
        end

        expect { klass.new.hello }.not_to raise_error('fail!')
        expect(klass.new.hello).to eq 'ok'
      end
    end

    it 'wraps instance method when deprecate_soft is called' do
      klass = Class.new do
        include DeprecateSoft

        def greet
          self.class.wrap_called = true
          'hello'
        end

        def self.wrap_called
          @wrap_called ||= false
        end

        def self.wrap_called=(val)
          @wrap_called = val
        end
      end

      klass.deprecate_soft(:greet, 'this is deprecated')

      expect(klass.wrap_called).to be false
      klass.new.greet
      expect(klass.wrap_called).to be true
    end

    it 'does not raise if called before defining an instance method' do
      klass = Class.new do
        include DeprecateSoft
        deprecate_soft :not_yet_defined, 'instance method not yet defined'
        def not_yet_defined
          'works, but no deprecate_soft'
        end
      end

      expect { klass.new.not_yet_defined }.not_to raise_error
      expect(klass.new.not_yet_defined).to eq 'works, but no deprecate_soft'
    end
  end
end
