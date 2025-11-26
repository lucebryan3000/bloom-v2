/**
 * useFeatureFlag Hook
 * Client-side hook for evaluating feature flags
 */

import { useEffect, useState } from 'react';

export function useFeatureFlag(flagId: string, userId: string) {
  const [enabled, setEnabled] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function evaluateFlag() {
      try {
        const response = await fetch(
          `/api/flags?evaluate=1&flag_id=${encodeURIComponent(flagId)}&user_id=${encodeURIComponent(userId)}`
        );

        if (!response.ok) {
          throw new Error('Failed to evaluate flag');
        }

        const result = await response.json();
        setEnabled(result.enabled);
      } catch (err) {
        setError(String(err));
        setEnabled(false);
      } finally {
        setLoading(false);
      }
    }

    evaluateFlag();
  }, [flagId, userId]);

  return { enabled, loading, error };
}

/**
 * Feature Flag Guard Component
 */
export function FeatureFlagGuard({
  flagId,
  userId,
  children,
  fallback = null,
}: {
  flagId: string;
  userId: string;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}) {
  const { enabled, loading } = useFeatureFlag(flagId, userId);

  if (loading) return null;
  if (enabled) return <>{children}</>;
  return <>{fallback}</>;
}
