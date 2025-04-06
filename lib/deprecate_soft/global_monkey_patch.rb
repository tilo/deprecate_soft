# frozen_string_literal: true

module DeprecateSoft
  module GlobalMonkeyPatch
    def deprecate_soft(method_name, message)
      extend DeprecateSoft::ClassMethods unless is_a?(DeprecateSoft::ClassMethods)
      deprecate_soft(method_name, message)
    end

    def deprecate_class_soft(method_name, message = nil)
      extend DeprecateSoft::ClassMethods unless is_a?(DeprecateSoft::ClassMethods)
      deprecate_class_soft(method_name, message)
    end
  end
end
