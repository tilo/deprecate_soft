
## 📝 DepracateSoft Change Log

## [1.2.0] - 2025-04-05
### ✨ Added Support
 - improving handling of class methods
 - added deprecate_class_soft for class methods. Fixed [Issue #1](https://github.com/tilo/deprecate_soft/issues/1)
 - support to define the method after the declaration
### 🛠️ Internals
 - stream-lined include DeprecateSoft
### 📐 Deliberate Limitations
 - Class methods need to be defined via `def self.method`, not in `class << self` blocks.
   Simply move the to-be-deprecated method out of the `self << class` and declare it via `self.method_name`.
   This also makes the to be deleted method stand out more.

## [1.1.0] - 2025-03-29
### ✨ Added Support
 - Errors in `before_hook` / `after_hook` do not prevent method execution.
 - `Kernel.warn` is used to log hook exceptions instead of raising.
 - No impact if `deprecate_soft` is called twice for the same method
### 🧪 Test Coverage
 - deprecate_soft called before method definition
 - deprecate_soft called twice
 - deprecate_soft for private instance and class methods
 - errors in `before_hook` or `after_hook` 
### 🛠️ Internals
 -  simplified initialization

## [1.0.0] - 2025-03-24
- Initial release of `deprecate_soft`.
- Support for soft-deprecating instance and class methods, as well as private methods.
- Added `before_hook` and `after_hook` for custom instrumentation or logging.
- Safe wrapping of methods with optional message.
- Skips wrapping if method is not yet defined.
- Supports defining deprecations inline with method definitions.

## [0.0.1] - 2025-03-22
 - pre-release
