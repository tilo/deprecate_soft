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

    # def hidden_method_name(method_name)
    #   "#{DeprecateSoft.prefix}#{method_name}_#{DeprecateSoft.suffix}"
    # end

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
    include MethodWrapper

    def deprecate_soft(method_name, message)
      DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: false)
    end
  end

  module ClassMethods
    include MethodWrapper

    def deprecate_soft(method_name, message)
      DeprecateSoft::MethodWrapper.wrap_method(self, method_name, message, is_class_method: true)
    end
  end
end
