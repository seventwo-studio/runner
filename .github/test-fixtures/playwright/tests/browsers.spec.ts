import { test, expect } from "@playwright/test";

test("launches browser and renders content", async ({ page, browserName }) => {
  await page.setContent(`<h1 id="greeting">Hello from ${browserName}</h1>`);

  const heading = page.locator("#greeting");
  await expect(heading).toBeVisible();
  await expect(heading).toContainText(`Hello from ${browserName}`);
});

test("executes JavaScript in page", async ({ page }) => {
  await page.goto("about:blank");

  const result = await page.evaluate(() => ({
    sum: 1 + 1,
    type: typeof window,
  }));

  expect(result.sum).toBe(2);
  expect(result.type).toBe("object");
});

test("PLAYWRIGHT_BROWSERS_PATH points to pre-installed browsers", async () => {
  expect(process.env.PLAYWRIGHT_BROWSERS_PATH).toBe(
    "/usr/local/share/ms-playwright"
  );
});
