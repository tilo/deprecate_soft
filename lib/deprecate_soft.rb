# frozen_string_literal: true

require_relative "deprecate_soft/version"

module DeprecateSoft
  class << self
    attr_accessor :before_hook, :after_hook

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
      original_method = instance_method(method_name)
      hidden_method_name = "__#{method_name}_original"

      define_method(hidden_method_name, original_method)

      define_method(method_name) do |*args, &block|
        full_method_name = "#{self.class}##{method_name}"
        DeprecateSoft.before_hook&.call(full_method_name, message, args: args) if DeprecateSoft.before_hook
        result = send(hidden_method_name, *args, &block)
        DeprecateSoft.after_hook&.call(full_method_name, message, result: result) if DeprecateSoft.after_hook
        result
      end
    end
  end

  module ClassMethods
    def deprecate_soft(method_name, message)
      original_method = method(method_name)
      hidden_method_name = "__#{method_name}_original"

      singleton_class.define_method(hidden_method_name, original_method)
      singleton_class.define_method(method_name) do |*args, &block|
        full_method_name = "#{self.name}.#{method_name}"
        DeprecateSoft.before_hook&.call(full_method_name, message, args: args) if DeprecateSoft.before_hook
        result = send(hidden_method_name, *args, &block)
        DeprecateSoft.after_hook&.call(full_method_name, message, result: result) if DeprecateSoft.after_hook
        result
      end
    end
  end
end
