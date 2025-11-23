# Test Melissa Command

Launch and test the Melissa.ai conversational agent interface.

## Usage
```
/test-melissa
```

## What This Does

1. **Starts** the development server if not already running
2. **Opens** the Melissa demo page at `http://localhost:3000/demo`
3. **Initializes** a test session
4. **Provides** test scenarios to try
5. **Monitors** conversation flow and data extraction

## Prerequisites

- Phase 2 must be completed (Melissa.ai implementation)
- Database must be initialized (`npx prisma generate`)
- Environment variables set (ANTHROPIC_API_KEY)

## Test Scenarios

The command provides these test scenarios:

### Scenario 1: Invoice Processing (Complete Flow)
```
User: We process invoices manually
Melissa: [asks clarifying questions]
User: About 40 hours per week
User: 5 people on the team
User: Average rate is $75 per hour
User: About 10% need corrections
User: I think 60% could be automated
User: 6 months timeline
```

### Scenario 2: Customer Onboarding
```
User: Customer onboarding takes too long
Melissa: [discovery questions]
User: 20 hours per week
User: 3 team members
User: $60 per hour average
```

### Scenario 3: Test Edge Cases
- Very short responses → Should trigger clarification
- Uncertain responses ("maybe", "not sure") → Low confidence
- Time check → After 12 minutes, should warn
- Invalid data → Should request correction

## What to Verify

### ✅ Conversation Flow
- Melissa greets appropriately
- Questions follow logical phases (discovery → metrics → validation)
- Phase transitions are smooth
- Time warnings appear after 12 minutes

### ✅ Data Extraction
- Numbers correctly extracted from text responses
- Currency values parsed properly
- Percentages identified
- Process names captured

### ✅ Confidence Scoring
- Clear responses → High confidence (>0.8)
- Adequate responses → Medium confidence (0.6-0.8)
- Vague responses → Low confidence (<0.6)
- Triggers clarification when needed

### ✅ UI/UX
- Messages appear in correct order
- Typing indicators show when loading
- Progress bar updates correctly
- Responsive on mobile

## Monitoring Output

The command displays real-time monitoring:

```
🤖 Melissa.ai Test Session Active

Session ID: sess_abc123
Phase: discovery
Progress: 25%
Confidence: 0.85 (high)

Recent Extractions:
- processName: "invoice processing"
- weeklyHours: 40
- teamSize: 5

Messages: 8 total (4 user, 4 assistant)
```

## Success Criteria

- ✅ Session initializes successfully
- ✅ Greeting message appears
- ✅ User messages send without errors
- ✅ Assistant responses arrive within 2 seconds
- ✅ Data extraction works for all types
- ✅ Phase transitions occur correctly
- ✅ Session data persists in database

## Troubleshooting

### Melissa not responding
- Check ANTHROPIC_API_KEY in `.env.local`
- Verify API key has credits
- Check console for errors

### Data not extracting
- Check response processor logs
- Verify metrics extractor patterns
- Test with more explicit responses

### Session not saving
- Check database connection
- Verify Prisma client generated
- Check session API endpoint

## Related Commands

- `/quick-test` - Run all quality checks
- `/db-refresh` - Reset database if sessions corrupted
- `/validate-roi` - Test the next phase (ROI calculations)
