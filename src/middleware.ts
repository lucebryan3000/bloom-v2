/**
 * Next.js Middleware
 * Handles authentication-based route protection
 *
 * Uncomment and configure the sections below to enable route protection.
 * @see https://authjs.dev/getting-started/session-management/protecting
 */

// import { auth } from '@/lib/auth';
// import { NextResponse } from 'next/server';

// export default auth((req) => {
//   const isLoggedIn = !!req.auth;
//   const isAuthPage = req.nextUrl.pathname.startsWith('/auth');
//   const isApiRoute = req.nextUrl.pathname.startsWith('/api');
//   const isPublicRoute = ['/'].includes(req.nextUrl.pathname);
//
//   // Allow API routes and public routes
//   if (isApiRoute || isPublicRoute) {
//     return NextResponse.next();
//   }
//
//   // Redirect logged-in users away from auth pages
//   if (isAuthPage && isLoggedIn) {
//     return NextResponse.redirect(new URL('/dashboard', req.url));
//   }
//
//   // Redirect unauthenticated users to sign in
//   if (!isLoggedIn && !isAuthPage) {
//     return NextResponse.redirect(new URL('/auth/signin', req.url));
//   }
//
//   return NextResponse.next();
// });

// Middleware matcher configuration
export const config = {
  matcher: [
    // Skip static files and images
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};

// Default export for when auth middleware is disabled
export default function middleware() {
  // No-op middleware - uncomment auth middleware above to enable
}
