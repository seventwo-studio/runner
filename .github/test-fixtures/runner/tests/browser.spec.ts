import { test, expect } from '@playwright/test';

test.describe('Playwright Browser Tests', () => {
  test('should launch browser with about:blank', async ({ page, browserName }) => {
    // Navigate to about:blank - works offline and tests browser launch
    await page.goto('about:blank');

    // Verify page is accessible
    const title = await page.title();
    expect(title).toBeDefined();

    console.log(`✓ ${browserName} browser launched successfully`);
  });

  test('should verify browser environment variables', async () => {
    // Check that PLAYWRIGHT_BROWSERS_PATH is set
    const browsersPath = process.env.PLAYWRIGHT_BROWSERS_PATH;
    expect(browsersPath).toBe('/usr/local/share/ms-playwright');
    console.log(`✓ PLAYWRIGHT_BROWSERS_PATH correctly set to: ${browsersPath}`);

    // PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD should NOT be set
    // This allows projects to install additional browser versions if there's a version mismatch
    const skipDownload = process.env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD;
    expect(skipDownload).toBeUndefined();
    console.log(`✓ PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD correctly unset (allows version flexibility)`);
  });

  test('should execute JavaScript in page', async ({ page, browserName }) => {
    await page.goto('about:blank');

    // Set content with JavaScript
    await page.setContent('<h1 id="test">Hello from Playwright</h1>');

    // Verify we can interact with the page
    const heading = page.locator('#test');
    await expect(heading).toBeVisible();
    await expect(heading).toContainText('Hello from Playwright');

    // Test JavaScript execution
    const result = await page.evaluate(() => {
      return {
        userAgent: navigator.userAgent,
        platform: navigator.platform,
        title: document.querySelector('#test')?.textContent
      };
    });

    expect(result.title).toBe('Hello from Playwright');
    console.log(`✓ ${browserName} successfully executed JavaScript`);
  });
});
