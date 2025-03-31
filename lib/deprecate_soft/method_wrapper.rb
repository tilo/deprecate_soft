# frozen_string_literal: true

module DeprecateSoft
  module MethodWrapper
    def self.wrap_method(context, method_name, message, is_class_method:)
      hidden_method_name = "#{DeprecateSoft.prefix}#{method_name}_#{DeprecateSoft.suffix}"

      if is_class_method
        target = context.singleton_class

        return if target.method_defined?(hidden_method_name) || target.private_method_defined?(hidden_method_name)

        original_method = context.method(method_name)
        target.define_method(hidden_method_name, original_method)

        target.define_method(method_name) do |*args, &block|
          klass_name = self.class.name || self.class.to_s
          full_name = "#{klass_name}.#{method_name}"

          begin
            DeprecateSoft.before_hook&.call(full_name, message, args: args)
          rescue StandardError => e
            warn "DeprecateSoft.before_hook error: #{e.class} - #{e.message}"
          end

          result = send(hidden_method_name, *args, &block)

          begin
            DeprecateSoft.after_hook&.call(full_name, message, result: result)
          rescue StandardError => e
            warn "DeprecateSoft.after_hook error: #{e.class} - #{e.message}"
          end

          result
        end
      else
        return if context.method_defined?(hidden_method_name) || context.private_method_defined?(hidden_method_name)

        original_method = context.instance_method(method_name)
        context.define_method(hidden_method_name, original_method)

        context.define_method(method_name) do |*args, &block|
          klass_name = self.class.name || self.to_s
          full_name = "#{klass_name}.#{method_name}"

          begin
            DeprecateSoft.before_hook&.call(full_name, message, args: args)
          rescue StandardError => e
            warn "DeprecateSoft.before_hook error: #{e.class} - #{e.message}"
          end

          result = send(hidden_method_name, *args, &block)

          begin
            DeprecateSoft.after_hook&.call(full_name, message, result: result)
          rescue StandardError => e
            warn "DeprecateSoft.after_hook error: #{e.class} - #{e.message}"
          end

          result
        end
      end
    end
  end
end
