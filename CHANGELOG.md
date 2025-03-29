
## 📝 DepracateSoft Change Log

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
