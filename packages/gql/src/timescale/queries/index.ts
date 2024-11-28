import type { PreparedQuery } from '@pgtyped/runtime';

// This interface represents the structure of our query modules
export interface QueryModule<P, R> {
  run: PreparedQuery<P, R>;
}

// Export all query modules here
// They will be automatically added by the generate script
export {};
