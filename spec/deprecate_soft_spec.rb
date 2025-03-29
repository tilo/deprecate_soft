# frozen_string_literal: true

require 'spec_helper'
require 'deprecate_soft'

RSpec.describe DeprecateSoft do
  before do
    DeprecateSoft.before_hook = nil
    DeprecateSoft.after_hook = nil
  end

  it 'has a version number' do
    expect(DeprecateSoft::VERSION).not_to be nil
  end

  it 'silently skips wrapping if method does not exist' do
    klass = Class.new do
      include DeprecateSoft
      deprecate_soft :nonexistent, 'no-op'
    end

    expect { klass.new }.not_to raise_error
  end

  describe 'instance method deprecation' do
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

      expect(called[0]).to match(/#hello/)
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

      expect(called[0]).to match(/#hello/)
      expect(called[1]).to eq('Use #greet instead')
      expect(called[2]).to eq('Hello, bar')
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

        deprecate_soft :foo, 'Use something else'
        deprecate_soft :bar, 'Use something else again'
      end

      obj = klass.new
      obj.foo
      obj.bar

      expect(called.size).to eq(2)
      expect(called[0][0]).to match(/#foo/)
      expect(called[1][0]).to match(/#bar/)
    end

    it 'does not wrap method if it is defined after deprecate_soft' do
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
      expect(called).to be false
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
  end

  describe 'class method deprecation' do
    let(:klass) do
      Class.new do
        include DeprecateSoft

        def self.hello(name)
          "Hi, #{name}"
        end

        deprecate_soft :hello, 'Use .greet instead'
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

    it 'wraps private class methods too' do
      klass = Class.new do
        extend DeprecateSoft

        class << self
          private

          def hidden; 'secret'; end
          deprecate_soft :hidden, 'no peeking'
        end

        def self.call_hidden
          hidden
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.send(:call_hidden)).to eq('secret')
      expect(called).to be true
    end

    it 'wraps private methods too' do
      klass = Class.new do
        include DeprecateSoft

        private

        def hidden; 'shh'; end
        deprecate_soft :hidden, 'no peeking'

        def call_hidden
          hidden
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.new.send(:call_hidden)).to eq('shh')
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
          deprecate_soft :foo, 'to be deleted'

          def self.bar; :bar; end
          deprecate_soft :bar, 'to be deleted'
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

    it 'does not wrap class method if it is defined after deprecate_soft' do
      klass = Class.new do
        include DeprecateSoft

        deprecate_soft :later_class_method, 'will be added'

        def self.later_class_method
          'defined later'
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.later_class_method).to eq('defined later')
      expect(called).to be false
    end

    it 'does not double-wrap class method if called twice on same method' do
      klass = Class.new do
        include DeprecateSoft

        def self.foo
          'foo'
        end

        deprecate_soft :foo, 'first warning'
        deprecate_soft :foo, 'second warning' # this will be ignored!
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
          def self.hello; 'ok'; end
          deprecate_soft :hello, 'failing hook'
        end

        expect { klass.hello }.not_to raise_error('fail!')
        expect(klass.hello).to eq 'ok'
      end

      it 'still runs method if after_hook raises' do
        DeprecateSoft.after_hook = ->(*) { raise 'fail!' }

        klass = Class.new do
          include DeprecateSoft
          def self.hello; 'ok'; end
          deprecate_soft :hello, 'failing hook'
        end

        expect { klass.hello }.not_to raise_error('fail!')
        expect(klass.hello).to eq 'ok'
      end
    end
  end

  describe 'incorrect usage of deprecate_soft' do
    it 'does not raise if called before defining an instance method' do
      klass = Class.new do
        include DeprecateSoft
        deprecate_soft :not_yet_defined, 'will define later'
        def not_yet_defined
          'ok'
        end
      end

      expect { klass.new.not_yet_defined }.not_to raise_error
    end

    it 'does not raise if called before defining a class method' do
      klass = Class.new do
        include DeprecateSoft
        deprecate_soft :not_yet_classy, 'class method not yet defined'
        def self.not_yet_classy
          'ok'
        end
      end

      expect { klass.not_yet_classy }.not_to raise_error
    end
  end
end
