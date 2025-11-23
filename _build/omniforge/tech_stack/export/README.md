# Export Phase Bootstrap Scripts

This directory contains bootstrap scripts for the **Export System** - multi-format business case export with professional formatting and narrative generation. These scripts set up:

1. **Export Infrastructure** - Core types, utilities, and narrative builders
2. **PDF Export** - React-based PDF generation with professional layout
3. **Excel Export** - Multi-sheet workbooks with formatted tables and charts
4. **JSON Export** - Complete data export for integration and archival
5. **Markdown Export** - GitHub-flavored Markdown for documentation and sharing

## Scripts

### export-system.sh

Sets up the core export infrastructure and shared utilities.

**Creates:**
- `src/lib/export/types.ts` - Complete BusinessCase type definition
- `src/lib/export/utils.ts` - Shared formatting utilities
- `src/lib/export/narrative.ts` - Narrative builders for sections

**Core Type: BusinessCase**

```typescript
interface BusinessCase {
  // Metadata
  id: string
  session_id: string
  generated_at: string
  version: string

  // Process information
  process_name: string
  process_description: string
  department: string
  participants: string[]

  // Current state
  current_state: {
    description: string
    volume_per_period: number
    period_unit: string
    cycle_time: number
    team_size: number
    annual_cost: number
  }

  // Proposed change
  proposed_change: {
    description: string
    change_type: string  // automation, redesign, tool_adoption, etc
    implementation_cost: number
    timeline_weeks: number
  }

  // Metrics & value
  metrics: Array<{ name, value, unit, confidence }>
  roi_results: ROIOutput
  confidence_snapshot: SessionConfidenceSnapshot

  // Narrative
  narrative: {
    executive_summary: string
    current_state_narrative: string
    proposed_change_narrative: string
    value_breakdown: string
    risks_and_assumptions: string
    recommendation: string
  }

  // Assumptions & risks
  key_assumptions: Array<{ assumption, impact, confidence }>
  key_risks: Array<{ risk, mitigation, likelihood }>
}
```

**Shared Utilities:**
- `generateFilename(businessCase, format)` → `bloom-{process}-{date}.{ext}`
- `formatCurrency(value)` → `$1,234.56`
- `formatPercent(value)` → `75.5%`
- `formatTimePeriod(months)` → `6 months` / `1.5 years`
- `sanitizeText(text)` → Remove HTML and control characters

**Narrative Builders:**
- `buildExecutiveSummary(businessCase)` - Key findings and recommendations
- `buildCurrentStateNarrative(businessCase)` - Current process description
- `buildValueNarrative(businessCase)` - Financial and operational value
- `buildAssumptionsNarrative(businessCase)` - Key assumptions and areas of uncertainty
- `buildRecommendationNarrative(businessCase)` - Final recommendation with confidence

**Reference:** PRD Section 6.12 - Export System

---

### pdf-export.sh

Sets up PDF export with react-to-print and professional layout.

**Creates:**
- `src/lib/export/pdf.ts` - PDF content preparation
- `src/components/export/PDFExport.tsx` - React component for printing

**Key Functions:**

```typescript
preparePDFContent(businessCase, options): {
  title: string
  sections: Array<{ heading, content, type }>
  metadata: Record<string, string>
}

generatePDFFilename(businessCase): string
```

**PDF Sections:**
1. Title & metadata (process name, date, confidence)
2. Executive Summary (key findings, ROI, payback period)
3. Current State (volume, cycle time, team size, annual cost)
4. Value Proposition (financial, operational, human dimensions)
5. ROI Analysis (conservative/base/aggressive scenarios as table)
6. Assumptions & Confidence (key assumptions, areas of uncertainty)
7. Recommendation (proceed/defer/strong recommend based on ROI and confidence)
8. Appendix (detailed metrics, data quality assessment, high uncertainty areas)

**PDF Options:**
- `include_logo` - Add company logo to header (default: true)
- `include_charts` - Include ROI analysis table (default: true)
- `include_appendix` - Include detailed metrics appendix (default: true)
- `page_orientation` - 'portrait' or 'landscape' (default: 'portrait')
- `footer_text` - Custom footer (default: 'Bloom Business Case Analysis')

**Component Usage:**

```tsx
import { PDFExport } from '@/components/export/PDFExport';

<PDFExport
  businessCase={case}
  onExported={() => console.log('PDF exported')}
/>
```

**Technologies:**
- `react-to-print` - Browser-native PDF printing
- `jsPDF` - PDF document generation
- `html2canvas` - DOM to canvas rendering

**Reference:** PRD Section 6.12 - PDF Export

---

### excel-export.sh

Sets up multi-sheet Excel workbook generation.

**Creates:**
- `src/lib/export/excel.ts` - Excel workbook preparation

**Excel Sheets:**

| Sheet | Contents |
|-------|----------|
| Executive Summary | Key metrics (process name, department, ROI, payback, confidence) |
| ROI Scenarios | Conservative/Base/Aggressive comparison table |
| Metrics | All extracted metrics with values, units, and confidence levels |
| Assumptions | Assumption/Impact/Confidence table with flagging |
| Risks | Risk/Mitigation/Likelihood assessment matrix |
| Data Quality | Confidence scores, data completeness, uncertainty areas |

**Key Functions:**

```typescript
prepareExcelWorkbook(businessCase): {
  sheets: Array<{
    name: string
    columns: string[]
    data: Array<Record<string, any>>
    formatting?: ExcelFormatting
  }>
  metadata: ExcelMetadata
}
```

**Formatting Features:**
- Header rows with background color and bold text
- Numeric formatting (currency for savings, percentages for ROI)
- Column widths optimized for readability
- Conditional formatting for confidence levels
- Freeze panes for data navigation

**Technologies:**
- `exceljs` - Excel file generation and formatting
- `@types/exceljs` - Type definitions

**Reference:** PRD Section 6.12 - Excel Export

---

### json-export.sh

Sets up comprehensive JSON export for integration and archival.

**Creates:**
- `src/lib/export/json.ts` - Complete JSON serialization

**JSON Structure:**

```typescript
interface JSONExport {
  export_metadata: {
    version: string
    generated_at: string
    format: 'json'
    bloom_version: string
  }

  business_case: BusinessCase

  analysis_context: {
    discovery_messages: number
    quantification_iterations: number
    validation_contradictions: number
    total_review_items: number
  }

  recommendation_action: 'strong_recommend' | 'recommend' | 'consider' | 'defer' | 'not_recommended'

  derivatives: {
    executive_summary_text: string
    financial_summary: { annual_savings, roi, payback }
    operational_summary: string
    human_summary: string
  }
}
```

**Decision Logic for Recommendation:**
- **strong_recommend**: ROI > 50% AND confidence > 75%
- **recommend**: ROI > 20% AND confidence > 60%
- **consider**: ROI > 0% AND confidence > 50%
- **defer**: ROI > -20%
- **not_recommended**: ROI < -20%

**Use Cases:**
- Integration with business systems (ERP, project management)
- Archival and historical tracking
- API endpoints returning business cases
- Data warehouse ingestion
- Audit trail and compliance reporting

**Reference:** PRD Section 6.12 - JSON Export

---

### markdown-export.sh

Sets up GitHub-flavored Markdown export for documentation.

**Creates:**
- `src/lib/export/markdown.ts` - Markdown content generation

**Markdown Sections:**

1. **Title** - Process name with business case designation
2. **Metadata** - Generated date, department, participants
3. **Table of Contents** - Navigable sections with anchors
4. **Executive Summary** - Key findings with emphasis
5. **Current State** - Process description with metrics
6. **Proposed Change** - Change type, description, cost, timeline
7. **Value Proposition** - Financial/operational/human dimensions
8. **ROI Analysis Table** - Conservative/base/aggressive scenarios
9. **Improvement Index** - Multi-dimensional value score
10. **Assumptions & Confidence** - Key assumptions with confidence levels
11. **Risks & Mitigations** - Risk assessment with emoji indicators
12. **Recommendation** - Final decision with rationale
13. **Appendix** - Detailed metrics and data quality assessment

**Markdown Features:**
- GitHub-flavored tables for structured data
- Emoji indicators (✅ high confidence, ⚠️ medium, ❌ low)
- Structured headings for navigation
- Code blocks for complex data
- Blockquotes for key findings
- Horizontal rules for visual separation

**Key Functions:**

```typescript
prepareMarkdownContent(businessCase, options): string

generateMarkdownFilename(businessCase): string
```

**Markdown Options:**
- `include_toc` - Table of contents (default: true)
- `include_metadata` - Header metadata (default: true)
- `include_appendix` - Detailed metrics (default: true)
- `heading_level` - Base heading level 1-3 (default: 1)

**Use Cases:**
- GitHub wiki documentation
- Internal knowledge base
- Email-friendly format
- Version control friendly (diffs work well)
- Slack/Discord posting

**Reference:** PRD Section 6.12 - Markdown Export

---

## Shared Narrative Pattern

All export formats use the same narrative builders for consistency:

```typescript
// All export formats call these functions
buildExecutiveSummary(businessCase)
buildCurrentStateNarrative(businessCase)
buildValueNarrative(businessCase)
buildAssumptionsNarrative(businessCase)
buildRecommendationNarrative(businessCase)
```

This ensures:
- **Consistency** - Same message across formats
- **Maintainability** - Update narratives in one place
- **Quality** - Professional copy written once, reused everywhere

## Export Flow

```
Business Case Data
  ↓
Narrative Builders
  ↓ (shared narrative generation)
Format-Specific Preparation
  ├─ PDF: preparePDFContent()
  ├─ Excel: prepareExcelWorkbook()
  ├─ JSON: buildJSONExport()
  └─ Markdown: prepareMarkdownContent()
  ↓
File Generation
  ├─ PDF: react-to-print
  ├─ Excel: ExcelJS
  ├─ JSON: JSON.stringify()
  └─ Markdown: plain text
  ↓
File Download/Upload
```

## Integration Points

Export system integrates with:

1. **Confidence Engine** - Uses confidence_snapshot for data quality statements
2. **ROI Engine** - Uses roi_results for financial sections
3. **HITL Review** - Uses audit trail for recommendation justification
4. **Settings** - Respects user export preferences (format, options, footer text)
5. **Monitoring** - Tracks export counts and formats

## Environment & Configuration

Set these in `bootstrap.conf`:

```bash
ENABLE_PDF_EXPORTS="true"
ENABLE_EXCEL_EXPORTS="true"
ENABLE_JSON_EXPORTS="true"
ENABLE_MARKDOWN_EXPORTS="true"

# Optional: Custom export settings
EXPORT_FOOTER_TEXT="Confidential - [Company Name]"
EXPORT_INCLUDE_LOGO="true"
EXPORT_DEFAULT_FORMAT="pdf"
```

## Dependencies

Export scripts require:
- **Packages:** `jsPDF`, `html2canvas`, `exceljs`, `markdown-it`, `remark`, `remark-html`
- **Interfaces:** BusinessCase, ROIOutput, SessionConfidenceSnapshot
- **Utilities:** formatCurrency, formatPercent, formatTimePeriod

## Quality Assurance

Recommendations for testing exports:

```bash
# Unit test narrative builders
pnpm test src/lib/export/narrative.test.ts

# Integration test with sample business case
pnpm test src/lib/export/__integration__/export-full-case.test.ts

# Manual testing
# 1. Create sample business case in app
# 2. Export as each format
# 3. Verify all sections present
# 4. Check formatting and layout
# 5. Validate data accuracy
```

## Performance Considerations

For large business cases:

- **PDF**: Limited by page breaks and rendering time
- **Excel**: Can handle 100k+ rows efficiently
- **JSON**: Suitable for archival and data transfer
- **Markdown**: Best for documentation and version control

Recommendation: Use JSON for archival, PDF for executive sharing, Excel for detailed analysis.

---

**Last Updated:** Bootstrap System v2.0
**Reference:** Bloom2 PRD Section 6.12 - Export System
