import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

// =============================================================================
// App Store - Global application state
// =============================================================================

interface AppState {
  // UI State
  sidebarOpen: boolean;
  theme: 'light' | 'dark' | 'system';

  // User State
  user: {
    id: string;
    email: string;
    name: string;
  } | null;

  // Actions
  toggleSidebar: () => void;
  setTheme: (theme: 'light' | 'dark' | 'system') => void;
  setUser: (user: AppState['user']) => void;
  clearUser: () => void;
}

export const useAppStore = create<AppState>()(
  devtools(
    persist(
      (set) => ({
        // Initial state
        sidebarOpen: true,
        theme: 'system',
        user: null,

        // Actions
        toggleSidebar: () =>
          set((state) => ({ sidebarOpen: !state.sidebarOpen })),

        setTheme: (theme) => set({ theme }),

        setUser: (user) => set({ user }),

        clearUser: () => set({ user: null }),
      }),
      {
        name: 'app-storage',
        partialize: (state) => ({
          theme: state.theme,
          sidebarOpen: state.sidebarOpen,
        }),
      }
    ),
    { name: 'AppStore' }
  )
);

// =============================================================================
// Selectors - For optimized re-renders
// =============================================================================

export const selectSidebarOpen = (state: AppState) => state.sidebarOpen;
export const selectTheme = (state: AppState) => state.theme;
export const selectUser = (state: AppState) => state.user;
export const selectIsAuthenticated = (state: AppState) => state.user !== null;
