# frozen_string_literal: true

require_relative 'deprecate_soft/version'

require_relative 'deprecate_soft/method_wrapper'

module DeprecateSoft
  class << self
    attr_accessor :before_hook, :after_hook
    attr_writer :prefix, :suffix

    def prefix
      @prefix || '__'
    end

    def suffix
      @suffix || 'deprecated'
    end

    def configure
      yield self
    end

    def included(base)
      base.extend InstanceMethods
    end

    def extended(base)
      base.extend ClassMethods
    end
  end

  module InstanceMethods
    def deprecate_soft(method_name, message)
      return unless method_defined?(method_name) || private_method_defined?(method_name)

      DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: false)
    end
  end

  module ClassMethods
    def deprecate_soft(method_name, message)
      return unless singleton_class.method_defined?(method_name) || singleton_class.private_method_defined?(method_name)

      DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: true)
    end
  end
end
