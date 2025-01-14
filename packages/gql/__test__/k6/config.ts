// Amount of trades to generate when seeding
export const TRADES_AMOUNT = 900_000; // ~500 trades per second
// Period over which trades are generated
export const START_DATE = new Date(Date.now() - 30 * 60 * 1000); // 30 minutes ago

// Stages for stress testing
export const STRESS_STAGES = [
  { duration: "30s", target: 1000 }, // Ramp up to 1,000 users over 30 seconds
  { duration: "1m", target: 1000 }, // Stay at 1,000 users
  { duration: "30s", target: 0 }, // Ramp down to 0 users over 30 seconds
];

// Thresholds for stress testing
export const STRESS_THRESHOLDS = {
  http_req_duration: ["p(95)<500"], // 95% of requests must complete below 500ms
  errors: ["rate<0.1"], // Error rate must be less than 10%
};
