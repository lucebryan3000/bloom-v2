---
id: tailwind-forms
topic: tailwind
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [tailwind-fundamentals, tailwind-utility-classes, tailwind-dark-mode]
related_topics: [forms, inputs, validation, accessibility, tailwindcss-forms]
embedding_keywords: [tailwind, forms, inputs, validation, checkbox, radio, select, textarea, form-plugin]
last_reviewed: 2025-11-16
---

# Tailwind CSS - Forms

Styling forms and form inputs with Tailwind CSS, including the @tailwindcss/forms plugin.

## Overview

Tailwind CSS provides utility classes for styling form elements. The official `@tailwindcss/forms` plugin offers beautiful default styles for form inputs with zero configuration.

---

## Installation

### @tailwindcss/forms Plugin

```bash
npm install @tailwindcss/forms
```

```javascript
// tailwind.config.js
module.exports = {
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
```

**What it does:**
- Provides consistent, beautiful default styles for all form elements
- Resets default browser styles
- Works with dark mode
- Fully customizable with utility classes

---

## Text Inputs

### Basic Text Input

```html
<!-- Without plugin -->
<input
  type="text"
  placeholder="Enter your name"
  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
/>

<!-- With @tailwindcss/forms plugin (cleaner) -->
<input
  type="text"
  placeholder="Enter your name"
  class="w-full rounded-lg border-gray-300 focus:border-blue-500 focus:ring-blue-500"
/>
```

### Input with Label

```html
<div class="mb-4">
  <label for="email" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Email Address
  </label>
  <input
    id="email"
    type="email"
    placeholder="you@example.com"
    class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
  />
</div>
```

### Input with Helper Text

```html
<div class="mb-4">
  <label for="username" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Username
  </label>
  <input
    id="username"
    type="text"
    placeholder="johndoe"
    class="w-full rounded-lg border-gray-300 focus:border-blue-500 focus:ring-blue-500"
  />
  <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
    Choose a unique username for your account.
  </p>
</div>
```

### Input with Icon

```html
<!-- Leading Icon -->
<div class="relative">
  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
    <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
    </svg>
  </div>
  <input
    type="email"
    placeholder="you@example.com"
    class="pl-10 w-full rounded-lg border-gray-300 focus:border-blue-500 focus:ring-blue-500"
  />
</div>

<!-- Trailing Icon (Clear Button) -->
<div class="relative">
  <input
    type="search"
    placeholder="Search..."
    class="pr-10 w-full rounded-lg border-gray-300 focus:border-blue-500 focus:ring-blue-500"
  />
  <button class="absolute inset-y-0 right-0 pr-3 flex items-center">
    <svg class="h-5 w-5 text-gray-400 hover:text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
    </svg>
  </button>
</div>
```

---

## Validation States

### Error State

```html
<div class="mb-4">
  <label for="email-error" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Email Address
  </label>
  <input
    id="email-error"
    type="email"
    value="invalid-email"
    class="w-full rounded-lg border-red-300 text-red-900 placeholder-red-300 focus:border-red-500 focus:ring-red-500"
  />
  <p class="mt-2 text-sm text-red-600 dark:text-red-400 flex items-center">
    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path>
    </svg>
    Please provide a valid email address.
  </p>
</div>
```

### Success State

```html
<div class="mb-4">
  <label for="email-success" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Email Address
  </label>
  <input
    id="email-success"
    type="email"
    value="user@example.com"
    class="w-full rounded-lg border-green-300 text-green-900 placeholder-green-300 focus:border-green-500 focus:ring-green-500"
  />
  <p class="mt-2 text-sm text-green-600 dark:text-green-400 flex items-center">
    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
    </svg>
    Email is valid!
  </p>
</div>
```

### Warning State

```html
<div class="mb-4">
  <label for="username-warning" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Username
  </label>
  <input
    id="username-warning"
    type="text"
    value="john"
    class="w-full rounded-lg border-yellow-300 text-yellow-900 placeholder-yellow-300 focus:border-yellow-500 focus:ring-yellow-500"
  />
  <p class="mt-2 text-sm text-yellow-600 dark:text-yellow-400 flex items-center">
    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path>
    </svg>
    Username is too short (minimum 6 characters).
  </p>
</div>
```

---

## Textarea

### Basic Textarea

```html
<div class="mb-4">
  <label for="message" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Message
  </label>
  <textarea
    id="message"
    rows="4"
    placeholder="Enter your message..."
    class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
  ></textarea>
</div>
```

### Textarea with Character Count

```html
<div class="mb-4">
  <label for="bio" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Bio
  </label>
  <textarea
    id="bio"
    rows="4"
    maxlength="500"
    placeholder="Tell us about yourself..."
    class="w-full rounded-lg border-gray-300 focus:border-blue-500 focus:ring-blue-500"
  ></textarea>
  <div class="mt-2 flex justify-between text-sm text-gray-500">
    <span>Maximum 500 characters</span>
    <span id="char-count">0 / 500</span>
  </div>
</div>

<script>
  const textarea = document.getElementById('bio')
  const charCount = document.getElementById('char-count')

  textarea.addEventListener('input', (e) => {
    const length = e.target.value.length
    charCount.textContent = `${length} / 500`
  })
</script>
```

---

## Select Dropdowns

### Basic Select

```html
<div class="mb-4">
  <label for="country" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Country
  </label>
  <select
    id="country"
    class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
  >
    <option>United States</option>
    <option>Canada</option>
    <option>United Kingdom</option>
    <option>Australia</option>
    <option>Germany</option>
  </select>
</div>
```

### Select with Placeholder

```html
<select class="w-full rounded-lg border-gray-300 focus:border-blue-500 focus:ring-blue-500">
  <option value="" selected disabled>Select a country</option>
  <option value="us">United States</option>
  <option value="ca">Canada</option>
  <option value="uk">United Kingdom</option>
</select>
```

### Multiple Select

```html
<div class="mb-4">
  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Select Technologies
  </label>
  <select
    multiple
    size="5"
    class="w-full rounded-lg border-gray-300 focus:border-blue-500 focus:ring-blue-500"
  >
    <option>React</option>
    <option>Vue</option>
    <option>Angular</option>
    <option>Svelte</option>
    <option>Next.js</option>
  </select>
</div>
```

---

## Checkboxes

### Basic Checkbox

```html
<div class="flex items-center mb-4">
  <input
    id="terms"
    type="checkbox"
    class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
  />
  <label for="terms" class="ml-2 text-sm text-gray-700 dark:text-gray-300">
    I agree to the terms and conditions
  </label>
</div>
```

### Checkbox List

```html
<fieldset class="mb-4">
  <legend class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
    Select your interests
  </legend>

  <div class="space-y-2">
    <div class="flex items-center">
      <input
        id="interest-1"
        type="checkbox"
        class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
      />
      <label for="interest-1" class="ml-2 text-sm text-gray-700 dark:text-gray-300">
        Web Development
      </label>
    </div>

    <div class="flex items-center">
      <input
        id="interest-2"
        type="checkbox"
        class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
      />
      <label for="interest-2" class="ml-2 text-sm text-gray-700 dark:text-gray-300">
        Mobile Development
      </label>
    </div>

    <div class="flex items-center">
      <input
        id="interest-3"
        type="checkbox"
        class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
      />
      <label for="interest-3" class="ml-2 text-sm text-gray-700 dark:text-gray-300">
        Data Science
      </label>
    </div>
  </div>
</fieldset>
```

### Checkbox with Description

```html
<div class="flex items-start mb-4">
  <div class="flex items-center h-5">
    <input
      id="newsletter"
      type="checkbox"
      class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
    />
  </div>
  <div class="ml-3">
    <label for="newsletter" class="text-sm font-medium text-gray-700 dark:text-gray-300">
      Subscribe to newsletter
    </label>
    <p class="text-sm text-gray-500 dark:text-gray-400">
      Get weekly updates about new features and product announcements.
    </p>
  </div>
</div>
```

---

## Radio Buttons

### Basic Radio Group

```html
<fieldset class="mb-4">
  <legend class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
    Choose a plan
  </legend>

  <div class="space-y-2">
    <div class="flex items-center">
      <input
        id="plan-free"
        type="radio"
        name="plan"
        value="free"
        class="w-4 h-4 text-blue-600 border-gray-300 focus:ring-blue-500"
      />
      <label for="plan-free" class="ml-2 text-sm text-gray-700 dark:text-gray-300">
        Free Plan
      </label>
    </div>

    <div class="flex items-center">
      <input
        id="plan-pro"
        type="radio"
        name="plan"
        value="pro"
        class="w-4 h-4 text-blue-600 border-gray-300 focus:ring-blue-500"
      />
      <label for="plan-pro" class="ml-2 text-sm text-gray-700 dark:text-gray-300">
        Pro Plan
      </label>
    </div>

    <div class="flex items-center">
      <input
        id="plan-enterprise"
        type="radio"
        name="plan"
        value="enterprise"
        class="w-4 h-4 text-blue-600 border-gray-300 focus:ring-blue-500"
      />
      <label for="plan-enterprise" class="ml-2 text-sm text-gray-700 dark:text-gray-300">
        Enterprise Plan
      </label>
    </div>
  </div>
</fieldset>
```

### Radio Cards

```html
<fieldset>
  <legend class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
    Delivery Method
  </legend>

  <div class="space-y-3">
    <!-- Standard Shipping -->
    <label class="relative flex cursor-pointer rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 p-4 hover:border-blue-500 dark:hover:border-blue-400 transition">
      <input type="radio" name="shipping" value="standard" class="sr-only" />
      <div class="flex items-center justify-between w-full">
        <div class="flex items-center">
          <div class="text-sm">
            <p class="font-medium text-gray-900 dark:text-gray-100">Standard Shipping</p>
            <p class="text-gray-500 dark:text-gray-400">4-7 business days</p>
          </div>
        </div>
        <div class="text-sm font-medium text-gray-900 dark:text-gray-100">$5.00</div>
      </div>
      <div class="absolute -inset-px rounded-lg border-2 border-blue-600 dark:border-blue-400 pointer-events-none hidden peer-checked:block"></div>
    </label>

    <!-- Express Shipping -->
    <label class="relative flex cursor-pointer rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 p-4 hover:border-blue-500 dark:hover:border-blue-400 transition">
      <input type="radio" name="shipping" value="express" class="sr-only" />
      <div class="flex items-center justify-between w-full">
        <div class="flex items-center">
          <div class="text-sm">
            <p class="font-medium text-gray-900 dark:text-gray-100">Express Shipping</p>
            <p class="text-gray-500 dark:text-gray-400">1-2 business days</p>
          </div>
        </div>
        <div class="text-sm font-medium text-gray-900 dark:text-gray-100">$15.00</div>
      </div>
    </label>
  </div>
</fieldset>
```

---

## File Upload

### Basic File Input

```html
<div class="mb-4">
  <label for="file-upload" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Upload File
  </label>
  <input
    id="file-upload"
    type="file"
    class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
  />
</div>
```

### Drag and Drop Area

```html
<div class="mb-4">
  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
    Upload Files
  </label>
  <div class="flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 dark:border-gray-600 border-dashed rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition">
    <div class="space-y-1 text-center">
      <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
        <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
      </svg>
      <div class="flex text-sm text-gray-600 dark:text-gray-400">
        <label for="file-upload-drag" class="relative cursor-pointer rounded-md font-medium text-blue-600 dark:text-blue-400 hover:text-blue-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-blue-500">
          <span>Upload a file</span>
          <input id="file-upload-drag" type="file" class="sr-only" />
        </label>
        <p class="pl-1">or drag and drop</p>
      </div>
      <p class="text-xs text-gray-500 dark:text-gray-400">
        PNG, JPG, GIF up to 10MB
      </p>
    </div>
  </div>
</div>
```

---

## Complete Form Examples

### Login Form

```html
<div class="max-w-md mx-auto bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
  <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">
    Sign In
  </h2>

  <form>
    <!-- Email -->
    <div class="mb-4">
      <label for="login-email" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Email
      </label>
      <input
        id="login-email"
        type="email"
        placeholder="you@example.com"
        class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
      />
    </div>

    <!-- Password -->
    <div class="mb-6">
      <label for="login-password" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Password
      </label>
      <input
        id="login-password"
        type="password"
        placeholder="••••••••"
        class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
      />
    </div>

    <!-- Remember Me & Forgot Password -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center">
        <input
          id="remember"
          type="checkbox"
          class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
        />
        <label for="remember" class="ml-2 text-sm text-gray-700 dark:text-gray-300">
          Remember me
        </label>
      </div>
      <a href="#" class="text-sm text-blue-600 dark:text-blue-400 hover:underline">
        Forgot password?
      </a>
    </div>

    <!-- Submit Button -->
    <button type="submit" class="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition">
      Sign In
    </button>

    <!-- Sign Up Link -->
    <p class="mt-4 text-center text-sm text-gray-600 dark:text-gray-400">
      Don't have an account?
      <a href="#" class="text-blue-600 dark:text-blue-400 hover:underline">
        Sign up
      </a>
    </p>
  </form>
</div>
```

### Contact Form

```html
<div class="max-w-2xl mx-auto bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
  <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">
    Contact Us
  </h2>

  <form>
    <!-- Name Fields -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
      <div>
        <label for="first-name" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          First Name
        </label>
        <input
          id="first-name"
          type="text"
          placeholder="John"
          class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
        />
      </div>
      <div>
        <label for="last-name" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Last Name
        </label>
        <input
          id="last-name"
          type="text"
          placeholder="Doe"
          class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
        />
      </div>
    </div>

    <!-- Email -->
    <div class="mb-4">
      <label for="contact-email" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Email
      </label>
      <input
        id="contact-email"
        type="email"
        placeholder="you@example.com"
        class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
      />
    </div>

    <!-- Subject -->
    <div class="mb-4">
      <label for="subject" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Subject
      </label>
      <select
        id="subject"
        class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
      >
        <option>General Inquiry</option>
        <option>Technical Support</option>
        <option>Billing</option>
        <option>Feedback</option>
      </select>
    </div>

    <!-- Message -->
    <div class="mb-6">
      <label for="contact-message" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Message
      </label>
      <textarea
        id="contact-message"
        rows="4"
        placeholder="Your message..."
        class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:border-blue-500 focus:ring-blue-500"
      ></textarea>
    </div>

    <!-- Submit Button -->
    <button type="submit" class="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition">
      Send Message
    </button>
  </form>
</div>
```

---

## AI Pair Programming Notes

**When to load this KB:**
- Styling forms with Tailwind CSS
- Implementing form validation states
- Creating accessible form components
- Using @tailwindcss/forms plugin

**Common starting points:**
- Text inputs: See Text Inputs
- Validation: See Validation States
- Forms plugin: See Installation → @tailwindcss/forms Plugin
- Complete examples: See Complete Form Examples

**Typical questions:**
- "How do I style form inputs?" → Text Inputs → Basic Text Input
- "How do I show validation errors?" → Validation States → Error State
- "How do I use the forms plugin?" → Installation
- "How do I create a login form?" → Complete Form Examples → Login Form

**Related topics:**
- Dark mode: See `06-DARK-MODE.md`
- Layout: See `05-LAYOUT-PATTERNS.md`
- Customization: See `04-CUSTOMIZATION.md`

---

**Last Updated**: 2025-11-16 | **KB Version**: 3.1
