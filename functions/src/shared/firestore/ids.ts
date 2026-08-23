export function friendshipId(firstUserId: string, secondUserId: string): string {
  return [firstUserId, secondUserId].sort().join("__");
}

export function normalizeUsername(username: string): string {
  return username.trim().toLowerCase();
}

export function utcDayKey(now: Date = new Date()): string {
  return now.toISOString().slice(0, 10);
}
