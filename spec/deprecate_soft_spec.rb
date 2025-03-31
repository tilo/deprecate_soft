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

  it 'adds soft_deprecate methods to the class (not the instance)' do
    klass = Class.new do
      include DeprecateSoft
    end

    expect(klass).to respond_to(:soft_deprecate)              # instance deprecation registration
    expect(klass).to respond_to(:soft_deprecate_class_method) # class deprecation registration
    expect(klass.new).not_to respond_to(:soft_deprecate)      # soft_deprecate is not meant to be called on the instance
  end

  it 'silently skips wrapping if method does not exist' do
    klass = Class.new do
      include DeprecateSoft
      soft_deprecate :nonexistent, 'no-op'
    end

    expect { klass.new }.not_to raise_error
  end
end
