## DepracateSoft Change Log

## [1.1.0] - 2025-03-29
 - simplify initialization
 - added tests for corner cases:
   - deprecate_soft called before method definition
   - deprecate_soft called twice
   - deprecate_soft for private methods
   - before_hook or after_hook raise
 - prevent double-wrapping methods
 - ensure that methods run undisturbed, even if the before_hook or after_hook raise an exception

## [1.0.0] - 2025-03-24
 - Initial release

## [0.0.1] - 2025-03-22
 - pre-release
