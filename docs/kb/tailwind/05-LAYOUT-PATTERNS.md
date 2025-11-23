---
id: tailwind-layout-patterns
topic: tailwind
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-utility-classes, tailwind-responsive-design]
related_topics: [layout, components, responsive-design, flexbox, grid]
embedding_keywords: [tailwind, layout, patterns, hero, cards, navigation, sidebar, footer, dashboard]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Layout Patterns

Common layout patterns and component structures built with Tailwind CSS utility classes.

## Overview

This guide covers production-ready layout patterns for common web components. Each pattern uses Tailwind's utility classes for responsive, accessible layouts.

---

## Hero Sections

### Simple Centered Hero

```html
<!-- Simple centered hero with CTA -->
<div class="bg-gradient-to-r from-blue-600 to-purple-600 text-white">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24 text-center">
    <h1 class="text-4xl sm:text-5xl lg:text-6xl font-bold mb-6">
      Welcome to Our Platform
    </h1>
    <p class="text-xl sm:text-2xl mb-8 text-blue-100 max-w-3xl mx-auto">
      Build amazing web applications with modern tools and best practices.
    </p>
    <div class="flex flex-col sm:flex-row gap-4 justify-center">
      <button class="bg-white text-blue-600 px-8 py-3 rounded-lg font-semibold hover:bg-blue-50 transition">
        Get Started
      </button>
      <button class="border-2 border-white px-8 py-3 rounded-lg font-semibold hover:bg-white/10 transition">
        Learn More
      </button>
    </div>
  </div>
</div>
```

### Split Hero with Image

```html
<!-- Two-column hero with image -->
<div class="bg-white">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 lg:py-24">
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
      <!-- Content -->
      <div>
        <h1 class="text-4xl lg:text-5xl font-bold text-gray-900 mb-6">
          Build faster with our tools
        </h1>
        <p class="text-lg text-gray-600 mb-8">
          Everything you need to create professional web applications.
          Fast, reliable, and built for scale.
        </p>
        <div class="flex flex-col sm:flex-row gap-4">
          <button class="bg-blue-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-700 transition">
            Start Free Trial
          </button>
          <button class="border border-gray-300 px-6 py-3 rounded-lg font-semibold hover:bg-gray-50 transition">
            View Demo
          </button>
        </div>

        <!-- Stats -->
        <div class="grid grid-cols-3 gap-8 mt-12">
          <div>
            <div class="text-3xl font-bold text-gray-900">99%</div>
            <div class="text-sm text-gray-600">Uptime</div>
          </div>
          <div>
            <div class="text-3xl font-bold text-gray-900">10k+</div>
            <div class="text-sm text-gray-600">Customers</div>
          </div>
          <div>
            <div class="text-3xl font-bold text-gray-900">24/7</div>
            <div class="text-sm text-gray-600">Support</div>
          </div>
        </div>
      </div>

      <!-- Image -->
      <div>
        <img
          src="/hero-image.jpg"
          alt="Hero illustration"
          class="rounded-lg shadow-2xl w-full h-auto"
        />
      </div>
    </div>
  </div>
</div>
```

### Full-Screen Hero with Background

```html
<!-- Full-screen hero with background image -->
<div class="relative h-screen">
  <!-- Background Image -->
  <div class="absolute inset-0 z-0">
    <img
      src="/background.jpg"
      alt="Background"
      class="w-full h-full object-cover"
    />
    <div class="absolute inset-0 bg-black/50"></div>
  </div>

  <!-- Content -->
  <div class="relative z-10 flex items-center justify-center h-full">
    <div class="text-center text-white px-4">
      <h1 class="text-5xl md:text-6xl lg:text-7xl font-bold mb-6">
        Transform Your Business
      </h1>
      <p class="text-xl md:text-2xl mb-12 max-w-2xl mx-auto">
        Discover the power of modern technology
      </p>
      <button class="bg-blue-600 text-white px-10 py-4 rounded-lg text-lg font-semibold hover:bg-blue-700 transition">
        Get Started Today
      </button>
    </div>
  </div>

  <!-- Scroll Indicator -->
  <div class="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
    <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>
    </svg>
  </div>
</div>
```

---

## Card Patterns

### Simple Card Grid

```html
<!-- 3-column responsive card grid -->
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
    <!-- Card 1 -->
    <div class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-xl transition">
      <img
        src="/card-image-1.jpg"
        alt="Card image"
        class="w-full h-48 object-cover"
      />
      <div class="p-6">
        <h3 class="text-xl font-bold text-gray-900 mb-2">
          Card Title
        </h3>
        <p class="text-gray-600 mb-4">
          Brief description of the card content goes here.
        </p>
        <a href="#" class="text-blue-600 font-semibold hover:text-blue-700">
          Learn More →
        </a>
      </div>
    </div>

    <!-- Card 2 -->
    <div class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-xl transition">
      <img
        src="/card-image-2.jpg"
        alt="Card image"
        class="w-full h-48 object-cover"
      />
      <div class="p-6">
        <h3 class="text-xl font-bold text-gray-900 mb-2">
          Card Title
        </h3>
        <p class="text-gray-600 mb-4">
          Brief description of the card content goes here.
        </p>
        <a href="#" class="text-blue-600 font-semibold hover:text-blue-700">
          Learn More →
        </a>
      </div>
    </div>

    <!-- Card 3 -->
    <div class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-xl transition">
      <img
        src="/card-image-3.jpg"
        alt="Card image"
        class="w-full h-48 object-cover"
      />
      <div class="p-6">
        <h3 class="text-xl font-bold text-gray-900 mb-2">
          Card Title
        </h3>
        <p class="text-gray-600 mb-4">
          Brief description of the card content goes here.
        </p>
        <a href="#" class="text-blue-600 font-semibold hover:text-blue-700">
          Learn More →
        </a>
      </div>
    </div>
  </div>
</div>
```

### Feature Card with Icon

```html
<!-- Feature card with icon and CTA -->
<div class="bg-white rounded-lg shadow-lg p-8 border border-gray-200 hover:border-blue-500 transition">
  <!-- Icon -->
  <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mb-4">
    <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
    </svg>
  </div>

  <!-- Content -->
  <h3 class="text-2xl font-bold text-gray-900 mb-3">
    Lightning Fast
  </h3>
  <p class="text-gray-600 mb-6">
    Optimized performance ensures your application runs at peak efficiency.
  </p>

  <!-- CTA -->
  <button class="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition">
    Get Started
  </button>
</div>
```

### Pricing Card

```html
<!-- Pricing card with features list -->
<div class="bg-white rounded-lg shadow-xl border-2 border-blue-600 overflow-hidden">
  <!-- Badge -->
  <div class="bg-blue-600 text-white text-center py-2 font-semibold">
    Most Popular
  </div>

  <!-- Pricing -->
  <div class="p-8">
    <h3 class="text-2xl font-bold text-gray-900 mb-4">Pro Plan</h3>
    <div class="mb-6">
      <span class="text-5xl font-bold text-gray-900">$29</span>
      <span class="text-gray-600">/month</span>
    </div>

    <!-- Features -->
    <ul class="space-y-4 mb-8">
      <li class="flex items-start">
        <svg class="w-5 h-5 text-green-500 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
        </svg>
        <span class="text-gray-700">Unlimited projects</span>
      </li>
      <li class="flex items-start">
        <svg class="w-5 h-5 text-green-500 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
        </svg>
        <span class="text-gray-700">Advanced analytics</span>
      </li>
      <li class="flex items-start">
        <svg class="w-5 h-5 text-green-500 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
        </svg>
        <span class="text-gray-700">Priority support</span>
      </li>
      <li class="flex items-start">
        <svg class="w-5 h-5 text-green-500 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
        </svg>
        <span class="text-gray-700">Custom integrations</span>
      </li>
    </ul>

    <!-- CTA Button -->
    <button class="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition">
      Choose Pro
    </button>
  </div>
</div>
```

---

## Navigation Patterns

### Desktop Navigation Bar

```html
<!-- Horizontal navigation with dropdown -->
<nav class="bg-white shadow-md">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="flex justify-between items-center h-16">
      <!-- Logo -->
      <div class="flex items-center">
        <img src="/logo.svg" alt="Logo" class="h-8 w-auto" />
        <span class="ml-2 text-xl font-bold text-gray-900">Brand</span>
      </div>

      <!-- Navigation Links -->
      <div class="hidden md:flex space-x-8">
        <a href="#" class="text-gray-700 hover:text-blue-600 font-medium transition">
          Home
        </a>
        <a href="#" class="text-gray-700 hover:text-blue-600 font-medium transition">
          Products
        </a>
        <a href="#" class="text-gray-700 hover:text-blue-600 font-medium transition">
          About
        </a>
        <a href="#" class="text-gray-700 hover:text-blue-600 font-medium transition">
          Contact
        </a>
      </div>

      <!-- CTA Button -->
      <div class="hidden md:block">
        <button class="bg-blue-600 text-white px-6 py-2 rounded-lg font-semibold hover:bg-blue-700 transition">
          Sign In
        </button>
      </div>

      <!-- Mobile Menu Button -->
      <div class="md:hidden">
        <button class="text-gray-700 hover:text-blue-600">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
          </svg>
        </button>
      </div>
    </div>
  </div>

  <!-- Mobile Menu (hidden by default) -->
  <div class="md:hidden border-t border-gray-200">
    <div class="px-2 pt-2 pb-3 space-y-1">
      <a href="#" class="block px-3 py-2 rounded-md text-gray-700 hover:bg-gray-100 font-medium">
        Home
      </a>
      <a href="#" class="block px-3 py-2 rounded-md text-gray-700 hover:bg-gray-100 font-medium">
        Products
      </a>
      <a href="#" class="block px-3 py-2 rounded-md text-gray-700 hover:bg-gray-100 font-medium">
        About
      </a>
      <a href="#" class="block px-3 py-2 rounded-md text-gray-700 hover:bg-gray-100 font-medium">
        Contact
      </a>
      <button class="w-full mt-2 bg-blue-600 text-white px-6 py-2 rounded-lg font-semibold hover:bg-blue-700 transition">
        Sign In
      </button>
    </div>
  </div>
</nav>
```

### Sidebar Navigation

```html
<!-- Vertical sidebar navigation -->
<div class="h-screen w-64 bg-gray-900 text-white fixed left-0 top-0">
  <!-- Logo -->
  <div class="p-6 border-b border-gray-800">
    <h1 class="text-2xl font-bold">Dashboard</h1>
  </div>

  <!-- Navigation Items -->
  <nav class="p-4">
    <a href="#" class="flex items-center px-4 py-3 mb-2 bg-blue-600 rounded-lg">
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
      </svg>
      Dashboard
    </a>

    <a href="#" class="flex items-center px-4 py-3 mb-2 text-gray-300 hover:bg-gray-800 rounded-lg transition">
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
      </svg>
      Users
    </a>

    <a href="#" class="flex items-center px-4 py-3 mb-2 text-gray-300 hover:bg-gray-800 rounded-lg transition">
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
      </svg>
      Analytics
    </a>

    <a href="#" class="flex items-center px-4 py-3 mb-2 text-gray-300 hover:bg-gray-800 rounded-lg transition">
      <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
      </svg>
      Settings
    </a>
  </nav>

  <!-- User Profile -->
  <div class="absolute bottom-0 w-64 p-4 border-t border-gray-800">
    <div class="flex items-center">
      <img src="/avatar.jpg" alt="User" class="w-10 h-10 rounded-full" />
      <div class="ml-3">
        <p class="font-semibold">John Doe</p>
        <p class="text-sm text-gray-400">john@example.com</p>
      </div>
    </div>
  </div>
</div>
```

---

## Sidebar Layouts

### App Layout with Sidebar

```html
<!-- Full app layout with fixed sidebar and main content -->
<div class="flex h-screen bg-gray-100">
  <!-- Sidebar (fixed) -->
  <aside class="w-64 bg-white shadow-lg">
    <!-- Sidebar content here -->
  </aside>

  <!-- Main Content Area -->
  <div class="flex-1 flex flex-col overflow-hidden">
    <!-- Top Navigation -->
    <header class="bg-white shadow-sm">
      <div class="px-6 py-4 flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>

        <!-- User Menu -->
        <div class="flex items-center space-x-4">
          <button class="text-gray-600 hover:text-gray-900">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path>
            </svg>
          </button>
          <img src="/avatar.jpg" alt="User" class="w-8 h-8 rounded-full" />
        </div>
      </div>
    </header>

    <!-- Main Content (scrollable) -->
    <main class="flex-1 overflow-y-auto p-6">
      <div class="max-w-7xl mx-auto">
        <!-- Your main content here -->
        <h2 class="text-3xl font-bold text-gray-900 mb-6">Welcome back!</h2>

        <!-- Example grid content -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-2">Card 1</h3>
            <p class="text-gray-600">Content here</p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-2">Card 2</h3>
            <p class="text-gray-600">Content here</p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-2">Card 3</h3>
            <p class="text-gray-600">Content here</p>
          </div>
        </div>
      </div>
    </main>
  </div>
</div>
```

### Collapsible Sidebar

```html
<!-- Sidebar that collapses on mobile -->
<div class="flex h-screen">
  <!-- Backdrop (mobile only) -->
  <div class="fixed inset-0 bg-black/50 z-40 lg:hidden" id="sidebar-backdrop"></div>

  <!-- Sidebar -->
  <aside class="fixed lg:static inset-y-0 left-0 z-50 w-64 bg-gray-900 text-white transform -translate-x-full lg:translate-x-0 transition-transform duration-300" id="sidebar">
    <!-- Close Button (mobile only) -->
    <div class="lg:hidden absolute top-4 right-4">
      <button class="text-white" id="close-sidebar">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
    </div>

    <!-- Sidebar Content -->
    <div class="p-6">
      <h1 class="text-2xl font-bold mb-8">App Name</h1>
      <!-- Navigation items -->
    </div>
  </aside>

  <!-- Main Content -->
  <div class="flex-1 flex flex-col">
    <!-- Mobile Header with Menu Button -->
    <header class="lg:hidden bg-white shadow-sm px-4 py-3">
      <button class="text-gray-600" id="open-sidebar">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
        </svg>
      </button>
    </header>

    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto p-6">
      <!-- Content here -->
    </main>
  </div>
</div>

<script>
  // Toggle sidebar on mobile
  const sidebar = document.getElementById('sidebar')
  const backdrop = document.getElementById('sidebar-backdrop')
  const openBtn = document.getElementById('open-sidebar')
  const closeBtn = document.getElementById('close-sidebar')

  openBtn?.addEventListener('click', () => {
    sidebar.classList.remove('-translate-x-full')
    backdrop.classList.remove('hidden')
  })

  closeBtn?.addEventListener('click', () => {
    sidebar.classList.add('-translate-x-full')
    backdrop.classList.add('hidden')
  })

  backdrop?.addEventListener('click', () => {
    sidebar.classList.add('-translate-x-full')
    backdrop.classList.add('hidden')
  })
</script>
```

---

## Footer Patterns

### Simple Footer

```html
<!-- Simple centered footer -->
<footer class="bg-gray-900 text-white py-12">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="text-center">
      <h3 class="text-2xl font-bold mb-4">Company Name</h3>
      <p class="text-gray-400 mb-6">
        Building amazing products since 2020
      </p>

      <!-- Social Links -->
      <div class="flex justify-center space-x-6 mb-8">
        <a href="#" class="text-gray-400 hover:text-white transition">
          <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
            <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
          </svg>
        </a>
        <a href="#" class="text-gray-400 hover:text-white transition">
          <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
            <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
          </svg>
        </a>
        <a href="#" class="text-gray-400 hover:text-white transition">
          <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
            <path fill-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clip-rule="evenodd"/>
          </svg>
        </a>
      </div>

      <!-- Copyright -->
      <p class="text-gray-500 text-sm">
        &copy; 2025 Company Name. All rights reserved.
      </p>
    </div>
  </div>
</footer>
```

### Multi-Column Footer

```html
<!-- Footer with multiple columns -->
<footer class="bg-gray-900 text-white py-12">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 mb-8">
      <!-- Company Info -->
      <div>
        <h3 class="text-xl font-bold mb-4">Company Name</h3>
        <p class="text-gray-400 mb-4">
          Making the world a better place through innovative solutions.
        </p>
        <div class="flex space-x-4">
          <a href="#" class="text-gray-400 hover:text-white transition">
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <!-- Facebook icon -->
            </svg>
          </a>
          <a href="#" class="text-gray-400 hover:text-white transition">
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <!-- Twitter icon -->
            </svg>
          </a>
        </div>
      </div>

      <!-- Products -->
      <div>
        <h4 class="font-semibold mb-4">Products</h4>
        <ul class="space-y-2">
          <li><a href="#" class="text-gray-400 hover:text-white transition">Features</a></li>
          <li><a href="#" class="text-gray-400 hover:text-white transition">Pricing</a></li>
          <li><a href="#" class="text-gray-400 hover:text-white transition">Security</a></li>
          <li><a href="#" class="text-gray-400 hover:text-white transition">Enterprise</a></li>
        </ul>
      </div>

      <!-- Company -->
      <div>
        <h4 class="font-semibold mb-4">Company</h4>
        <ul class="space-y-2">
          <li><a href="#" class="text-gray-400 hover:text-white transition">About</a></li>
          <li><a href="#" class="text-gray-400 hover:text-white transition">Blog</a></li>
          <li><a href="#" class="text-gray-400 hover:text-white transition">Careers</a></li>
          <li><a href="#" class="text-gray-400 hover:text-white transition">Press</a></li>
        </ul>
      </div>

      <!-- Legal -->
      <div>
        <h4 class="font-semibold mb-4">Legal</h4>
        <ul class="space-y-2">
          <li><a href="#" class="text-gray-400 hover:text-white transition">Privacy</a></li>
          <li><a href="#" class="text-gray-400 hover:text-white transition">Terms</a></li>
          <li><a href="#" class="text-gray-400 hover:text-white transition">License</a></li>
          <li><a href="#" class="text-gray-400 hover:text-white transition">Cookie Policy</a></li>
        </ul>
      </div>
    </div>

    <!-- Bottom Bar -->
    <div class="border-t border-gray-800 pt-8">
      <p class="text-center text-gray-500 text-sm">
        &copy; 2025 Company Name, Inc. All rights reserved.
      </p>
    </div>
  </div>
</footer>
```

---

## Dashboard Layouts

### Stats Dashboard

```html
<!-- Dashboard with stats cards -->
<div class="p-6 bg-gray-100 min-h-screen">
  <div class="max-w-7xl mx-auto">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">Dashboard Overview</h1>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <!-- Stat Card 1 -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between mb-4">
          <div class="text-sm font-medium text-gray-600">Total Revenue</div>
          <div class="p-3 bg-blue-100 rounded-full">
            <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
          </div>
        </div>
        <div class="text-3xl font-bold text-gray-900 mb-2">$45,231</div>
        <div class="text-sm text-green-600 flex items-center">
          <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
          </svg>
          12% from last month
        </div>
      </div>

      <!-- Stat Card 2 -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between mb-4">
          <div class="text-sm font-medium text-gray-600">New Users</div>
          <div class="p-3 bg-green-100 rounded-full">
            <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
          </div>
        </div>
        <div class="text-3xl font-bold text-gray-900 mb-2">2,345</div>
        <div class="text-sm text-green-600 flex items-center">
          <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
          </svg>
          8% from last month
        </div>
      </div>

      <!-- Stat Card 3 -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between mb-4">
          <div class="text-sm font-medium text-gray-600">Orders</div>
          <div class="p-3 bg-purple-100 rounded-full">
            <svg class="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path>
            </svg>
          </div>
        </div>
        <div class="text-3xl font-bold text-gray-900 mb-2">1,234</div>
        <div class="text-sm text-red-600 flex items-center">
          <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M14.707 10.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 12.586V5a1 1 0 012 0v7.586l2.293-2.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
          </svg>
          3% from last month
        </div>
      </div>

      <!-- Stat Card 4 -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between mb-4">
          <div class="text-sm font-medium text-gray-600">Conversion Rate</div>
          <div class="p-3 bg-amber-100 rounded-full">
            <svg class="w-6 h-6 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
            </svg>
          </div>
        </div>
        <div class="text-3xl font-bold text-gray-900 mb-2">3.24%</div>
        <div class="text-sm text-green-600 flex items-center">
          <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
          </svg>
          0.5% from last month
        </div>
      </div>
    </div>

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Chart 1 -->
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Revenue Chart</h3>
        <div class="h-64 bg-gray-100 rounded flex items-center justify-center">
          <p class="text-gray-500">Chart placeholder</p>
        </div>
      </div>

      <!-- Chart 2 -->
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">User Growth</h3>
        <div class="h-64 bg-gray-100 rounded flex items-center justify-center">
          <p class="text-gray-500">Chart placeholder</p>
        </div>
      </div>
    </div>
  </div>
</div>
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Building page layouts and component structures
- Implementing navigation patterns
- Creating card-based UIs
- Designing dashboard interfaces

**Common starting points:**
- Hero sections: See Hero Sections
- Cards: See Card Patterns
- Navigation: See Navigation Patterns
- Dashboards: See Dashboard Layouts

**Typical questions:**
- "How do I create a hero section?" → Hero Sections
- "How do I build a card grid?" → Card Patterns → Simple Card Grid
- "How do I make a responsive navigation?" → Navigation Patterns
- "How do I build a dashboard?" → Dashboard Layouts

**Related topics:**
- Responsive design: See `03-RESPONSIVE-DESIGN.md`
- Components: See `04-CUSTOMIZATION.md` → Custom Components
- Dark mode: See `06-DARK-MODE.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
