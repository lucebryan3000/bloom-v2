import { test, expect } from '@playwright/test';

test.describe('Example E2E Tests', () => {
  test('homepage loads successfully', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/.*/);
  });

  test('page has main content', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('main')).toBeVisible();
  });
});
