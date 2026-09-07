export interface RateLimiter {
  checkLimit(input: { ip: string; userId: string }): Promise<boolean>;
}

export class InMemoryRateLimiter implements RateLimiter {
  private readonly ipRequests = new Map<string, { count: number; resetAt: number }>();
  private readonly userRequests = new Map<string, { count: number; resetAt: number }>();

  // Limits: 100 requests per IP per minute, 50 requests per User per minute
  private readonly maxIpLimit = 100;
  private readonly maxUserLimit = 50;
  private readonly windowMs = 60000;

  async checkLimit({ ip, userId }: { ip: string; userId: string }): Promise<boolean> {
    const now = Date.now();

    // Check IP
    const ipData = this.ipRequests.get(ip);
    if (ipData && ipData.resetAt > now) {
      if (ipData.count >= this.maxIpLimit) {
        return false;
      }
      ipData.count += 1;
    } else {
      this.ipRequests.set(ip, { count: 1, resetAt: now + this.windowMs });
    }

    // Check User
    const userData = this.userRequests.get(userId);
    if (userData && userData.resetAt > now) {
      if (userData.count >= this.maxUserLimit) {
        return false;
      }
      userData.count += 1;
    } else {
      this.userRequests.set(userId, { count: 1, resetAt: now + this.windowMs });
    }

    return true;
  }
}
