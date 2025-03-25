# frozen_string_literal: true

module DeprecateSoft
  module MethodWrapper
    def self.wrap_method(context, method_name, message, is_class_method:)
      hidden_method_name = "#{DeprecateSoft.prefix}#{method_name}_#{DeprecateSoft.suffix}"

      if is_class_method
        original_method = context.method(method_name)

        context.singleton_class.define_method(hidden_method_name, original_method)

        context.singleton_class.define_method(method_name) do |*args, &block|
          full_name = "#{self.name}.#{method_name}"
          DeprecateSoft.before_hook&.call(full_name, message, args: args) if defined?(DeprecateSoft.before_hook)
          result = send(hidden_method_name, *args, &block)
          DeprecateSoft.after_hook&.call(full_name, message, result: result) if defined?(DeprecateSoft.after_hook)
          result
        end
      else
        original_method = context.instance_method(method_name)

        context.define_method(hidden_method_name, original_method)

        context.define_method(method_name) do |*args, &block|
          full_name = "#{self.class}##{method_name}"
          DeprecateSoft.before_hook&.call(full_name, message, args: args) if defined?(DeprecateSoft.before_hook)
          result = send(hidden_method_name, *args, &block)
          DeprecateSoft.after_hook&.call(full_name, message, result: result) if defined?(DeprecateSoft.after_hook)
          result
        end
      end
    end
  end
end
