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

        soft_deprecate_class_method :hello, 'Use .greet instead'
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

    # private class methods need to be defined via self.method_name
    it 'wraps private class methods too' do
      klass = Class.new do
        include DeprecateSoft

        private_class_method def self.hidden; 'secret'; end
        soft_deprecate_class_method :hidden, 'no peeking'

        def self.call_hidden
          hidden
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.send(:call_hidden)).to eq('secret')
      expect(called).to be true
    end

    it 'does not wrap private class methods declared in self block without an include' do
      class BadExample
        include DeprecateSoft

        class << self
          # DeprecateSoft is not properly enabled!!
          def hidden; 'secret'; end
          private_class_method :hidden
          soft_deprecate_class_method :hidden, 'no peeking'
        end

        def self.call_hidden
          send(:hidden)
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(BadExample.send(:hidden)).to eq('secret')
      expect(called).to be false
    end

    it 'wraps private class methods declared in self block with extra include' do
      class Klass2
        include DeprecateSoft

        DeprecateSoft.define_class_methods(self) do
          def hidden; 'secret'; end
          private_class_method :hidden
          soft_deprecate_class_method :hidden, 'no peeking'
        end

        def self.call_hidden
          send(:hidden)
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(Klass2.send(:call_hidden)).to eq('secret')
      expect(called).to be true
    end

    it 'wraps private class methods declared in self block with manual include and wrap' do
      class Klass3
        include DeprecateSoft

        class << self
          include DeprecateSoft::ClassMethods
          @_pending_soft_wraps ||= {}

          def hidden; 'secret'; end
          private_class_method :hidden
          soft_deprecate_class_method :hidden, 'no peeking'
        end

        # Must run wrap_pending_class_methods manually
        DeprecateSoft.wrap_pending_class_methods(self)

        def self.call_hidden
          send(:hidden)
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(Klass3.send(:call_hidden)).to eq('secret')
      expect(called).to be true
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

    describe 'with multiple deprecated methods' do
      let(:klass) do
        Class.new do
          include DeprecateSoft

          def self.foo; :foo; end
          soft_deprecate_class_method :foo, 'to be deleted'

          def self.bar; :bar; end
          soft_deprecate_class_method :bar, 'to be deleted'
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

    it 'wraps class method even if it is defined after soft_deprecate' do
      klass = Class.new do
        include DeprecateSoft

        soft_deprecate_class_method :later_class_method, 'will be added'

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

        soft_deprecate_class_method :foo, 'first warning'
        soft_deprecate_class_method :foo, 'second warning' # this will be ignored!
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
          soft_deprecate_class_method :hello, 'failing hook'
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
          soft_deprecate_class_method :hello, 'failing hook'
        end

        expect { klass.hello }.not_to raise_error('fail!')
        expect(klass.hello).to eq 'works'
      end
    end

    it 'wraps class method when soft_deprecate is called' do
      klass = Class.new do
        def self.hello
          'hi'
        end

        extend DeprecateSoft::ClassMethods
      end

      allow(DeprecateSoft::MethodWrapper).to receive(:wrap_method).and_call_original

      klass.soft_deprecate_class_method(:hello, 'this is deprecated')

      expect(DeprecateSoft::MethodWrapper).to have_received(:wrap_method).with(
        klass, :hello, 'this is deprecated', is_class_method: true
      )
    end

    it 'does not raise if called before defining a class method' do
      klass = Class.new do
        include DeprecateSoft
        soft_deprecate_class_method :not_yet_defined, 'class method not yet defined'
        def self.not_yet_defined
          'works, but no soft_deprecate'
        end
      end

      expect { klass.not_yet_defined }.not_to raise_error
      expect(klass.not_yet_defined).to eq 'works, but no soft_deprecate'
    end
  end
end
