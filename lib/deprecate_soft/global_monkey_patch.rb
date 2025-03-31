# frozen_string_literal: true

module DeprecateSoft
  module GlobalMonkeyPatch
    def soft_deprecate(method_name, message)
      if singleton_class.method_defined?(method_name) || singleton_class.private_method_defined?(method_name)
        DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: true)
      elsif instance_methods.include?(method_name) || private_instance_methods.include?(method_name)
        DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: false)
      else
        # allow soft_deprecate to happen after method is defined
        @__pending_soft_wraps ||= {}
        @__pending_soft_wraps[method_name] = message
      end
    end

    def soft_deprecate_class_method(method_name, message = nil)
      if singleton_class.method_defined?(method_name) || singleton_class.private_method_defined?(method_name)
        DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: true)
      else
        singleton_class.instance_variable_set(:@_pending_soft_wraps, {}) unless singleton_class.instance_variable_defined?(:@_pending_soft_wraps)
        singleton_class.instance_variable_get(:@_pending_soft_wraps)[method_name] = message
      end
    end
  end
end
