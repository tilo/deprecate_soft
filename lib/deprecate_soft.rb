# frozen_string_literal: true

# require all files under lib/deprecate_soft
Dir[File.join(__dir__, 'deprecate_soft', '*.rb')].sort.each do |file|
  require file
end

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

    def prefixed_name(method_name)
      "#{prefix}#{method_name}_#{suffix}".to_sym
    end

    def included(base)
      base.extend(ClassMethods)

      base.define_singleton_method(:method_added) do |method_name|
        pending = base.instance_variable_get(:@__pending_soft_wraps)
        if pending&.key?(method_name)
          DeprecateSoft::MethodWrapper.wrap_method(base, method_name, pending.delete(method_name), is_class_method: false)
        end
        super(method_name) if defined?(super)
      end

      base.singleton_class.define_method(:singleton_method_added) do |method_name|
        pending = instance_variable_get(:@_pending_soft_wraps)
        if pending&.key?(method_name)
          DeprecateSoft::MethodWrapper.wrap_method(base, method_name, pending.delete(method_name), is_class_method: true)
        end
        super(method_name) if defined?(super)
      end
    end
  end

  module ClassMethods
    def deprecate_soft(method_name, message = nil)
      hidden = DeprecateSoft.prefixed_name(method_name)

      if method_defined?(method_name) || private_method_defined?(method_name)
        return if method_defined?(hidden) || private_method_defined?(hidden)

        DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: false)
      else
        @__pending_soft_wraps ||= {}
        @__pending_soft_wraps[method_name] = message
      end
    end

    def deprecate_class_soft(method_name, message = nil)
      hidden = DeprecateSoft.prefixed_name(method_name)
      target = singleton_class

      if target.method_defined?(method_name) || target.private_method_defined?(method_name)
        return if target.method_defined?(hidden) || target.private_method_defined?(hidden)

        DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: true)
      else
        @_pending_soft_wraps ||= {}
        @_pending_soft_wraps[method_name] = message
      end
    end
  end
end
