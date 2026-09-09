export type RateLimitScope = "upload" | "delivery";

export interface RateLimitDecision {
  readonly allowed: boolean;
  readonly retryAfterSeconds: number;
}

export interface RateLimiter {
  checkLimit(input: {
    ip: string;
    userId: string;
    scope: RateLimitScope;
  }): Promise<RateLimitDecision>;
}

interface Counter {
  count: number;
  resetAt: number;
}

export class InMemoryRateLimiter implements RateLimiter {
  constructor(
    private readonly now: () => number = Date.now,
    private readonly limits: Readonly<Record<RateLimitScope, number>> = {
      upload: 20,
      delivery: 50,
    },
    private readonly maxIpLimit = 100,
    private readonly windowMs = 60_000,
  ) {}

  private readonly counters = new Map<string, Counter>();

  async checkLimit({ ip, userId, scope }: {
    ip: string;
    userId: string;
    scope: RateLimitScope;
  }): Promise<RateLimitDecision> {
    const now = this.now();
    const ipDecision = this.consume(`ip:${ip}`, this.maxIpLimit, now);
    if (!ipDecision.allowed) return ipDecision;
    return this.consume(`user:${userId}:${scope}`, this.limits[scope], now);
  }

  private consume(key: string, limit: number, now: number): RateLimitDecision {
    const counter = this.counters.get(key);
    if (counter === undefined || counter.resetAt <= now) {
      this.counters.set(key, { count: 1, resetAt: now + this.windowMs });
      return { allowed: true, retryAfterSeconds: 0 };
    }
    if (counter.count >= limit) {
      return {
        allowed: false,
        retryAfterSeconds: Math.max(1, Math.ceil((counter.resetAt - now) / 1000)),
      };
    }
    counter.count += 1;
    return { allowed: true, retryAfterSeconds: 0 };
  }
}
