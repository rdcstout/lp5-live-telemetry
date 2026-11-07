'use strict';

function parseVersion(input) {
  const match = String(input || '').trim().match(/^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?$/);
  if (!match) return null;
  return { parts: match.slice(1, 4).map(Number), prerelease: match[4] || null };
}

function compareVersions(left, right) {
  const a = parseVersion(left);
  const b = parseVersion(right);
  if (!a || !b) throw new Error('A release version could not be compared.');
  for (let index = 0; index < 3; index += 1) {
    if (a.parts[index] !== b.parts[index]) return a.parts[index] > b.parts[index] ? 1 : -1;
  }
  if (a.prerelease === b.prerelease) return 0;
  if (!a.prerelease) return 1;
  if (!b.prerelease) return -1;
  return a.prerelease.localeCompare(b.prerelease, undefined, { numeric: true });
}

function eligibleStableRelease(release) {
  if (!release || release.draft || release.prerelease) throw new Error('No eligible stable release was returned.');
  const parsed = parseVersion(release.tag_name);
  if (!parsed || parsed.prerelease) throw new Error('The latest release has an invalid stable version.');
  return { version: parsed.parts.join('.'), url: release.html_url };
}

module.exports = { compareVersions, eligibleStableRelease, parseVersion };
