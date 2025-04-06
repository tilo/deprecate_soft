# frozen_string_literal: true

require 'spec_helper'
require 'deprecate_soft'

RSpec.describe DeprecateSoft do
  before do
    DeprecateSoft.before_hook = nil
    DeprecateSoft.after_hook = nil
  end

  describe 'deprecate Class Methods' do
    let(:klass) do
      Class.new do
        include DeprecateSoft

        def self.hello(name)
          "Hi, #{name}"
        end

        deprecate_class_soft :hello, 'Use .greet instead'
      end
    end

    it 'returns the original result' do
      expect(klass.hello('Alice')).to eq('Hi, Alice')
    end

    it 'does not raise for class method if before_hook is nil' do
      DeprecateSoft.before_hook = nil
      expect { klass.hello('admin') }.not_to raise_error
    end

    it 'calls before_hook if defined' do
      called = nil
      DeprecateSoft.before_hook = lambda do |method, message, args:|
        called = [method, message, args]
      end

      klass.hello('Bob')

      expect(called[0]).to match(/\.hello/)
      expect(called[1]).to eq('Use .greet instead')
      expect(called[2]).to eq(['Bob'])
    end

    it 'does not raise for class method if before_hook is nil' do
      DeprecateSoft.before_hook = nil
      expect { klass.hello('admin') }.not_to raise_error
    end

    it 'calls after_hook if defined' do
      called = nil
      DeprecateSoft.after_hook = lambda do |method, message, result:|
        called = [method, message, result]
      end

      klass.hello('Zoe')

      expect(called[0]).to match(/\.hello/)
      expect(called[1]).to eq('Use .greet instead')
      expect(called[2]).to eq('Hi, Zoe')
    end

    it 'wraps private class methods defined via self.method_name' do
      klass = Class.new do
        include DeprecateSoft

        private_class_method def self.hidden; 'secret'; end
        deprecate_class_soft :hidden, 'to be deleted'

        def self.call_hidden
          hidden
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.send(:call_hidden)).to eq('secret')
      expect(called).to be true
    end

    it 'does not handle class methods declared in self block, but does not affect method calls' do
      class SelfBlocksAreHandled
        include DeprecateSoft

        class << self
          include DeprecateSoft

          def class_method; 'hello'; end
          deprecate_class_soft :class_method, 'to be deleted' # intentionally will not work!
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(SelfBlocksAreHandled.class_method).to eq('hello') # method calls are not affected
      expect(called).to be false # intentionally will not work!
    end

    describe 'with multiple deprecated methods' do
      let(:klass) do
        Class.new do
          include DeprecateSoft

          def self.foo; :foo; end
          deprecate_class_soft :foo, 'to be deleted'

          def self.bar; :bar; end
          deprecate_class_soft :bar, 'to be deleted'
        end
      end

      it 'handles multiple class method deprecations correctly' do
        called = []

        DeprecateSoft.before_hook = lambda do |method, message, args:|
          called << [method, message]
        end

        klass.foo
        klass.bar

        expect(called.size).to eq(2)
        expect(called[0][0]).to match(/\.foo/)
        expect(called[1][0]).to match(/\.bar/)
      end
    end

    it 'wraps class method even if it is defined after deprecate_class_soft' do
      klass = Class.new do
        include DeprecateSoft

        deprecate_class_soft :later_class_method, 'will be added'

        def self.later_class_method
          'defined later'
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.later_class_method).to eq('defined later')
      expect(called).to be true
    end

    it 'does not double-wrap class method if called twice on same method' do
      klass = Class.new do
        include DeprecateSoft

        def self.foo
          'foo'
        end

        deprecate_class_soft :foo, 'first warning'
        deprecate_class_soft :foo, 'second warning' # this will be ignored!
      end

      calls = []
      DeprecateSoft.before_hook = ->(method, message, args:) { calls << message }

      klass.foo
      expect(calls).to eq(['first warning']) # not ['first warning', 'second warning']
    end

    describe 'when hooks raise an exception' do
      it 'still runs method if before_hook raises' do
        DeprecateSoft.before_hook = ->(*) { raise 'fail!' }

        klass = Class.new do
          include DeprecateSoft
          def self.hello
            'works'
          end
          deprecate_class_soft :hello, 'failing hook'
        end

        expect { klass.hello }.not_to raise_error('fail!')
        expect(klass.hello).to eq 'works'
      end

      it 'still runs method if after_hook raises' do
        DeprecateSoft.after_hook = ->(*) { raise 'fail!' }

        klass = Class.new do
          include DeprecateSoft
          def self.hello
            'works'
          end
          deprecate_class_soft :hello, 'failing hook'
        end

        expect { klass.hello }.not_to raise_error('fail!')
        expect(klass.hello).to eq 'works'
      end
    end

    it 'wraps class method when deprecate_class_soft is called' do
      klass = Class.new do
        def self.hello
          'hi'
        end

        include DeprecateSoft::ClassMethods
      end

      allow(DeprecateSoft::MethodWrapper).to receive(:wrap_method).and_call_original

      klass.deprecate_class_soft(:hello, 'this is deprecated')

      expect(DeprecateSoft::MethodWrapper).to have_received(:wrap_method).with(
        klass, :hello, 'this is deprecated', is_class_method: true
      )
    end

    it 'does not raise if called before defining a class method' do
      klass = Class.new do
        include DeprecateSoft
        deprecate_class_soft :not_yet_defined, 'class method not yet defined'
        def self.not_yet_defined
          'works, but no deprecate_class_soft'
        end
      end

      expect { klass.not_yet_defined }.not_to raise_error
      expect(klass.not_yet_defined).to eq 'works, but no deprecate_class_soft'
    end
  end
end
