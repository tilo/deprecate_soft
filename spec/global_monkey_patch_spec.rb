# frozen_string_literal: true

require 'spec_helper'
require 'deprecate_soft'
require 'deprecate_soft/global_monkey_patch'

# Enable the global patch for this file only
class Module
  include DeprecateSoft::GlobalMonkeyPatch
end

RSpec.describe 'DeprecateSoft::GlobalMonkeyPatch' do
  before do
    DeprecateSoft.before_hook = nil
    DeprecateSoft.after_hook = nil
  end

  describe 'instance method deprecation with global patch' do
    let(:klass) do
      Class.new do
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

    it 'allows deprecate_soft on instance method defined later' do
      klass = Class.new do
        include DeprecateSoft

        deprecate_soft :later_instance_method, 'will be removed'

        def later_instance_method
          'hi'
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.new.later_instance_method).to eq('hi')
      expect(called).to be true
    end

    it 'tracks pending instance method in global monkey patch if not included' do
      klass = Class.new do
        include DeprecateSoft

        deprecate_soft :delayed, 'will be added later'

        def delayed
          'hello'
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.new.delayed).to eq('hello')
      expect(called).to be true
    end
  end

  describe 'class method deprecation with global patch' do
    let(:klass) do
      Class.new do
        def self.hello(name)
          "Hi, #{name}"
        end

        deprecate_class_soft :hello, 'Use .greet instead'
      end
    end

    it 'returns the original result' do
      expect(klass.hello('Alice')).to eq('Hi, Alice')
    end

    it 'does not raise if before_hook is nil' do
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

    it 'allows deprecate_class_soft on class method defined later' do
      klass = Class.new do
        include DeprecateSoft

        deprecate_class_soft :later_class_method, 'deprecated'

        def self.later_class_method
          'yo'
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.later_class_method).to eq('yo')
      expect(called).to be true
    end

    it 'tracks pending class method in global monkey patch if not included' do
      klass = Class.new do
        include DeprecateSoft

        deprecate_class_soft :delayed_class_method, 'will be added later'

        def self.delayed_class_method
          'world'
        end
      end

      called = false
      DeprecateSoft.before_hook = ->(*) { called = true }

      expect(klass.delayed_class_method).to eq('world')
      expect(called).to be true
    end
  end

  describe 'incorrect usage of deprecate_soft with global monkey patch' do
    it 'does not raise if called before defining an instance method' do
      klass = Class.new do
        deprecate_class_soft :not_yet_defined, 'will define later'
        def not_yet_defined
          'ok'
        end
      end

      expect { klass.new.not_yet_defined }.not_to raise_error
    end

    it 'does not raise if called before defining a class method' do
      klass = Class.new do
        deprecate_class_soft :not_yet_classy, 'class method not yet defined'
        def self.not_yet_classy
          'ok'
        end
      end

      expect { klass.not_yet_classy }.not_to raise_error
    end
  end
end
