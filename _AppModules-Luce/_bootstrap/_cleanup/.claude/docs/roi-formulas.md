# ROI Formulas Quick Reference

Fast reference for all ROI calculation formulas used in Appmelia Bloom.

## Core ROI Formula

```
ROI % = ((Total Benefits - Total Costs) / Total Costs) × 100
```

**Example:**
- Benefits: $200,000
- Costs: $50,000
- ROI = (($200,000 - $50,000) / $50,000) × 100 = **300%**

---

## Net Present Value (NPV)

```
NPV = Σ(CFt / (1 + r)^t) - C₀

Where:
  CFt = Cash flow at time t
  r = Discount rate
  t = Time period
  C₀ = Initial investment
```

**Implementation:**
```typescript
function calculateNPV(
  cashFlows: number[],
  discountRate: number,
  initialInvestment: number
): number {
  const presentValue = cashFlows.reduce((sum, cf, t) => {
    return sum + cf / Math.pow(1 + discountRate, t + 1);
  }, 0);

  return presentValue - initialInvestment;
}
```

**Example:**
- Initial Investment: $50,000
- Year 1 CF: $30,000
- Year 2 CF: $35,000
- Year 3 CF: $40,000
- Discount Rate: 10%

```
NPV = $30,000/(1.1)¹ + $35,000/(1.1)² + $40,000/(1.1)³ - $50,000
NPV = $27,273 + $28,926 + $30,053 - $50,000
NPV = $36,252
```

---

## Internal Rate of Return (IRR)

```
0 = NPV = Σ(CFt / (1 + IRR)^t) - C₀
```

Solve for IRR using Newton-Raphson method:

```typescript
function calculateIRR(
  cashFlows: number[],
  initialInvestment: number,
  guess: number = 0.1
): number {
  const maxIterations = 100;
  const tolerance = 0.0001;

  let irr = guess;

  for (let i = 0; i < maxIterations; i++) {
    const npv = -initialInvestment + cashFlows.reduce(
      (sum, cf, t) => sum + cf / Math.pow(1 + irr, t + 1), 0
    );

    const derivative = cashFlows.reduce(
      (sum, cf, t) => sum - (t + 1) * cf / Math.pow(1 + irr, t + 2), 0
    );

    const newIrr = irr - npv / derivative;

    if (Math.abs(newIrr - irr) < tolerance) {
      return newIrr;
    }

    irr = newIrr;
  }

  throw new Error('IRR did not converge');
}
```

**Example:**
- Same cash flows as above
- IRR ≈ **52.5%**

---

## Payback Period

```
Payback Period = Initial Investment / Annual Cash Flow

(For uneven cash flows, cumulative method)
```

**Implementation:**
```typescript
function calculatePaybackPeriod(
  monthlyCashFlow: number,
  initialInvestment: number
): number {
  if (monthlyCashFlow <= 0) {
    return Infinity; // Never pays back
  }

  return initialInvestment / monthlyCashFlow;
}
```

**Example:**
- Initial Investment: $50,000
- Monthly Cash Flow: $8,000
- Payback = $50,000 / $8,000 = **6.25 months**

---

## Total Cost of Ownership (TCO)

```
TCO = Direct Costs + Indirect Costs - Residual Value

Direct Costs = Initial Investment + Recurring Costs
Indirect Costs = Training + Support + Opportunity Cost
```

**Implementation:**
```typescript
function calculateTCO(
  directCosts: number,
  indirectCosts: number,
  timeframeYears: number,
  residualValue: number = 0
): number {
  const totalDirectCosts = directCosts * timeframeYears;
  const totalIndirectCosts = indirectCosts * timeframeYears;

  return totalDirectCosts + totalIndirectCosts - residualValue;
}
```

**Example:**
- Direct Costs: $30,000/year
- Indirect Costs: $10,000/year
- Timeframe: 3 years
- Residual Value: $20,000
- TCO = ($30k × 3) + ($10k × 3) - $20k = **$100,000**

---

## Break-Even Analysis

```
Break-Even Point = Fixed Costs / (Price - Variable Cost)

For time:
Break-Even Time = Initial Investment / Net Benefit per Period
```

**Implementation:**
```typescript
function calculateBreakEven(
  initialInvestment: number,
  monthlySavings: number,
  monthlyCosts: number
): number {
  const netBenefit = monthlySavings - monthlyCosts;

  if (netBenefit <= 0) {
    return Infinity;
  }

  return initialInvestment / netBenefit;
}
```

---

## Confidence Score

```
Confidence = Σ(Weight_i × Factor_i) / Σ(Weight_i)

Factors:
  - Completeness (30%)
  - Quality (25%)
  - Historical Data (20%)
  - Industry Benchmarks (15%)
  - Assumptions (10%)
```

**Implementation:**
```typescript
function calculateConfidence(metrics: ExtractedMetrics): number {
  const factors = {
    completeness: assessCompleteness(metrics) * 0.30,
    quality: assessQuality(metrics) * 0.25,
    historical: assessHistorical(metrics) * 0.20,
    benchmarks: assessBenchmarks(metrics) * 0.15,
    assumptions: assessAssumptions(metrics) * 0.10,
  };

  return Object.values(factors).reduce((sum, v) => sum + v, 0) * 100;
}
```

**Score Interpretation:**
- **90-100**: Very High Confidence ✅
- **80-89**: High Confidence ✅
- **60-79**: Medium Confidence ⚠️
- **40-59**: Low Confidence ⚠️
- **0-39**: Very Low Confidence ❌

---

## Sensitivity Analysis

```
Sensitivity = (Δ Output / Output) / (Δ Input / Input)

For each variable, calculate:
  - Optimistic scenario (+20%)
  - Pessimistic scenario (-20%)
  - Impact on NPV
```

**Implementation:**
```typescript
function calculateSensitivity(
  baseInputs: ROIInputs,
  variable: keyof ROIInputs
): SensitivityResult {
  const baseNPV = calculateNPV(baseInputs);

  // Optimistic: +20%
  const optimisticInputs = { ...baseInputs };
  optimisticInputs[variable] *= 1.2;
  const optimisticNPV = calculateNPV(optimisticInputs);

  // Pessimistic: -20%
  const pessimisticInputs = { ...baseInputs };
  pessimisticInputs[variable] *= 0.8;
  const pessimisticNPV = calculateNPV(pessimisticInputs);

  return {
    variable,
    baseNPV,
    optimisticNPV,
    pessimisticNPV,
    impact: Math.abs(optimisticNPV - pessimisticNPV) / baseNPV,
  };
}
```

---

## Annualized Return

```
Annualized Return = (Ending Value / Beginning Value)^(1 / Years) - 1
```

**Example:**
- Beginning: $50,000
- Ending: $200,000
- Years: 3
- Annualized Return = ($200k / $50k)^(1/3) - 1 = **58.7% per year**

---

## Cost Savings Calculation

```
Annual Savings = (Current Annual Cost × Automation %) - Solution Cost

Current Annual Cost = Weekly Hours × 52 × Hourly Rate × Team Size
```

**Example:**
- Weekly Hours: 40
- Hourly Rate: $75
- Team Size: 5
- Automation: 60%
- Solution Cost: $25,000/year

```
Current Cost = 40 × 52 × $75 × 5 = $780,000/year
Savings = ($780,000 × 0.60) - $25,000 = $443,000/year
```

---

## Risk-Adjusted Return

```
Risk-Adjusted Return = Expected Return × (1 - Risk Factor)

Risk Factor based on:
  - Data confidence
  - Implementation complexity
  - Market volatility
```

**Implementation:**
```typescript
function calculateRiskAdjustedReturn(
  expectedReturn: number,
  confidenceScore: number,
  complexity: number // 0-1
): number {
  const riskFactor = (1 - confidenceScore) * complexity;
  return expectedReturn * (1 - riskFactor);
}
```

---

## Quick Reference Table

| Metric | Formula | Good Value | Red Flag |
|--------|---------|------------|----------|
| ROI % | (Benefit - Cost) / Cost × 100 | > 100% | < 25% |
| NPV | Σ(CF/(1+r)^t) - C₀ | > $0 | < $0 |
| IRR | Solve NPV = 0 | > 20% | < Discount Rate |
| Payback | Investment / Monthly CF | < 12 months | > 24 months |
| Confidence | Weighted factors | > 70% | < 50% |

---

## Common Pitfalls

❌ **Forgetting time value of money**
- Always discount future cash flows

❌ **Ignoring indirect costs**
- Training, support, opportunity cost matter

❌ **Overly optimistic automation %**
- Be conservative (30-70% typical)

❌ **Not accounting for ramp-up time**
- Full benefits may take 3-6 months

❌ **Ignoring residual value**
- Systems may have value at end of analysis period

---

## File Locations

- Implementation: `lib/roi/calculator.ts`
- Types: `lib/roi/types.ts`
- Confidence: `lib/roi/confidence.ts`
- Sensitivity: `lib/roi/sensitivity.ts`
- Tests: `tests/unit/roi/calculator.test.ts`
