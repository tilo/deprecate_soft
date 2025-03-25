# frozen_string_literal: true

module DeprecateSoft
  module GlobalMonkeyPatch
    def deprecate_soft(method_name, message)
      if self.singleton_class.method_defined?(method_name) || self.singleton_class.private_method_defined?(method_name)
        # Class method
        DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: true)
      elsif self.instance_methods.include?(method_name) || self.private_instance_methods.include?(method_name)
        # Instance method
        DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: false)
      else # rubocop:disable Style/EmptyElse
        #  protect against declaring deprecate_soft before method is defined
        #
        # Do nothing — fail-safe in production
      end
    end
  end
end
