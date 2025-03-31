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

        soft_deprecate :hello, 'Use #greet instead'
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

    # this fails: we can not wrap private methods at this time
    xit 'wraps private methods too' do
      klass = Class.new do
        include DeprecateSoft

        private

        def hidden; 'shh'; end
        soft_deprecate_class_method :hidden, 'no peeking'

        def call_hidden
          hidden
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.new.send(:call_hidden)).to eq('shh')
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

        soft_deprecate :foo, 'to be deleted'
        soft_deprecate :bar, 'also to be deleted'
      end

      obj = klass.new
      obj.foo
      obj.bar

      expect(called.size).to eq(2)
      expect(called[0][0]).to match(/\.foo/)
      expect(called[1][0]).to match(/\.bar/)
    end

    it 'wraps method even if it is defined after soft_deprecate' do
      klass = Class.new do
        include DeprecateSoft
        soft_deprecate :later_method, 'will be added'
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

        soft_deprecate :foo, 'first warning'
        soft_deprecate :foo, 'second warning' # this will be ignored!
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
          soft_deprecate :hello, 'failing hook'
        end

        expect { klass.new.hello }.not_to raise_error('fail!')
        expect(klass.new.hello).to eq 'ok'
      end

      it 'still runs method if after_hook raises' do
        DeprecateSoft.after_hook = ->(*) { raise 'fail!' }

        klass = Class.new do
          include DeprecateSoft
          def hello; 'ok'; end
          soft_deprecate :hello, 'failing hook'
        end

        expect { klass.new.hello }.not_to raise_error('fail!')
        expect(klass.new.hello).to eq 'ok'
      end
    end

    it 'wraps instance method when soft_deprecate is called' do
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

      klass.soft_deprecate(:greet, 'this is deprecated')

      expect(klass.wrap_called).to be false
      klass.new.greet
      expect(klass.wrap_called).to be true
    end

    it 'does not raise if called before defining an instance method' do
      klass = Class.new do
        include DeprecateSoft
        soft_deprecate_class_method :not_yet_defined, 'class method not yet defined'
        def not_yet_defined
          'works, but no soft_deprecate'
        end
      end

      expect { klass.new.not_yet_defined }.not_to raise_error
      expect(klass.new.not_yet_defined).to eq 'works, but no soft_deprecate'
    end
  end
end
