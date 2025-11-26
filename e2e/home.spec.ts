import { test, expect } from '@playwright/test';

test.describe('Home Page', () => {
  test('should display welcome message', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('h1')).toBeVisible();
  });

  test('should have correct title', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/My App/);
  });
});
