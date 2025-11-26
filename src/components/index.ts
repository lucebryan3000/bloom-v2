/**
 * Components Root Export
 *
 * Re-exports all component categories for convenient imports.
 * Prefer importing from specific directories for tree-shaking.
 *
 * @example
 * // Preferred: import from specific directory
 * import { Button } from '@/components/ui';
 *
 * // Alternative: import from root (may affect tree-shaking)
 * import { Button } from '@/components';
 */

export * from './ui';
export * from './common';
export * from './forms';
export * from './layout';
