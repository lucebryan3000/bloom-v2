# Validate ROI Command

Test ROI calculation engine with comprehensive scenarios and edge cases.

## Usage
```
/validate-roi [scenario]
```

## Scenarios Available

### Basic Scenarios
- `simple` - Basic ROI with straightforward numbers
- `complex` - Multi-year with variable cash flows
- `negative` - Negative ROI scenario
- `edge-cases` - Boundary conditions

### Industry Scenarios
- `invoice-processing` - Typical invoice automation
- `customer-onboarding` - Onboarding optimization
- `data-entry` - Manual data entry automation
- `report-generation` - Automated reporting

### All Scenarios
- `all` - Run all test scenarios (default)

## What This Does

1. **Loads** predefined test scenarios with known inputs
2. **Executes** ROI calculations using the engine
3. **Validates** results against expected values
4. **Tests** all calculation methods:
   - Net Present Value (NPV)
   - Internal Rate of Return (IRR)
   - Payback Period
   - Total Cost of Ownership (TCO)
   - ROI Percentage
5. **Checks** confidence scoring accuracy
6. **Verifies** sensitivity analysis
7. **Reports** any discrepancies

## Sample Output

```
🧮 ROI Calculation Validation

Running scenario: invoice-processing

════════════════════════════════════════════════════

INPUT PARAMETERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Process: Invoice Processing Automation
Weekly Hours: 40
Team Size: 5
Hourly Rate: $75
Annual Cost: $156,000
Initial Investment: $50,000
Expected Automation: 60%
Timeline: 3 years

════════════════════════════════════════════════════

CALCULATED RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NPV: $186,420 ✅
  Expected: $185,000 - $190,000
  Variance: +0.8%

IRR: 94.2% ✅
  Expected: 90% - 100%
  Variance: -5.8%

Payback Period: 6.4 months ✅
  Expected: 6 - 7 months
  Within range: Yes

TCO (3 years): $98,500 ✅
  Expected: $95,000 - $100,000
  Variance: +3.5%

ROI: 372% ✅
  Expected: 350% - 400%
  Within range: Yes

════════════════════════════════════════════════════

CONFIDENCE SCORE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Overall: 87% (HIGH) ✅

Breakdown:
  Data Completeness: 95% ✅
  Data Quality: 90% ✅
  Historical Data: 80% ⚠️
  Industry Benchmarks: 85% ✅
  Assumptions: 80% ⚠️

════════════════════════════════════════════════════

SENSITIVITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Critical Variables (Impact on NPV):

1. Automation % ████████████████████ 45% impact
   Range: 40% - 80%
   NPV Range: $124k - $248k

2. Hourly Rate ███████████████░░░░░ 32% impact
   Range: $60 - $90
   NPV Range: $149k - $223k

3. Team Size ████████░░░░░░░░░░░░ 18% impact
   Range: 3 - 7
   NPV Range: $111k - $261k

4. Timeline ███░░░░░░░░░░░░░░░░░░ 5% impact
   Range: 2 - 5 years
   NPV Range: $175k - $195k

════════════════════════════════════════════════════

✅ All calculations PASSED
⚠️  2 warnings (historical data, assumptions)
❌ 0 errors

════════════════════════════════════════════════════
```

## Validation Criteria

### NPV Calculation
- ✅ Properly discounts future cash flows
- ✅ Handles negative initial investment
- ✅ Correct for multiple time periods
- ✅ Applies correct discount rate

### IRR Calculation
- ✅ Converges to solution
- ✅ Handles multiple IRR scenarios
- ✅ Returns null for no solution
- ✅ Within 0.1% of expected value

### Payback Period
- ✅ Calculates months correctly
- ✅ Handles partial months
- ✅ Returns null if never pays back
- ✅ Accounts for uneven cash flows

### TCO Calculation
- ✅ Includes all direct costs
- ✅ Includes indirect costs
- ✅ Accounts for residual value
- ✅ Projects over full timeframe

### Confidence Scoring
- ✅ Weighted factors correct
- ✅ Score between 0-100
- ✅ Flags low confidence correctly
- ✅ Identifies critical gaps

### Sensitivity Analysis
- ✅ Tests all key variables
- ✅ Calculates impact correctly
- ✅ Generates tornado diagram data
- ✅ Identifies critical variables

## Edge Cases Tested

```
❌ Edge Case: Zero Investment
   Input: initialInvestment = 0
   Expected: Infinite ROI or error
   Result: ✅ Returns error with helpful message

❌ Edge Case: Negative Benefits
   Input: monthlyBenefit = -1000
   Expected: Negative ROI
   Result: ✅ Calculates correctly, flags as warning

❌ Edge Case: Very Long Timeframe
   Input: timeframe = 50 years
   Expected: Warning about projection uncertainty
   Result: ✅ Warns and caps confidence score

❌ Edge Case: No Automation Potential
   Input: automationPotential = 0%
   Expected: Zero benefit
   Result: ✅ Returns $0 benefit, suggests review

❌ Edge Case: Immediate Payback
   Input: monthlyBenefit > initialInvestment
   Expected: Payback < 1 month
   Result: ✅ Returns 0.x months correctly
```

## When to Use

Run this command:
- **After implementing** Phase 3 ROI calculations
- **Before committing** ROI engine changes
- **After modifying** calculation formulas
- **When debugging** unexpected ROI values
- **Before production** deployment

## Troubleshooting

### NPV calculation fails
```typescript
// Check discount rate
console.log('Discount Rate:', calculator.discountRate);

// Verify cash flow array
console.log('Cash Flows:', cashFlows);

// Test with simple scenario
/validate-roi simple
```

### IRR won't converge
```typescript
// Check initial guess
// Verify cash flows aren't all same sign
// May indicate no valid IRR exists
```

### Confidence score always low
```typescript
// Check confidence factor weights
// Verify data completeness checks
// Review threshold values
```

## Prerequisites

- Phase 3 ROI calculator implemented
- Test data files exist in `tests/fixtures/roi-scenarios.ts`
- All dependencies installed

## Output Files

Creates validation report:
- `tests/reports/roi-validation-{timestamp}.md`
- `tests/reports/roi-validation-{timestamp}.json`

## Related Commands

- `/quick-test` - Run all tests including ROI
- `/test-melissa` - Test data collection feeding into ROI
- `/check-progress` - See Phase 3 completion status
