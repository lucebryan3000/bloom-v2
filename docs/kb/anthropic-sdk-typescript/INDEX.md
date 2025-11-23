---
id: anthropic-sdk-typescript-index
topic: anthropic-sdk-typescript
file_role: navigation
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['anthropic-sdk-typescript']
embedding_keywords: [anthropic-sdk-typescript, index, navigation, map]
last_reviewed: 2025-11-13
---

# Anthropic SDK TypeScript - Complete Index

**Knowledge Base Version:** 1.0.1
**Last Updated:** November 13, 2025
**SDK Version:** @anthropic-ai/sdk 0.27.3
**Claude Model:** claude-sonnet-4-5-20250929

---

## 📚 Complete Documentation Index

### Quick Access

| Need | Document | Description |
|------|----------|-------------|
| 🚀 **Getting Started** | [Installation & Setup](01-INSTALLATION-SETUP.md) | Installation, environment setup, client configuration |
| ⚡ **Quick Lookup** | [Quick Reference](QUICK-REFERENCE.md) | Fast reference for common patterns and code snippets |
| 📚 **Deep Dive** | [Comprehensive Guide](COMPREHENSIVE-GUIDE.md) | Complete technical reference with all topics |
| 🏗️ **Integration Examples** | [Integration Patterns](FRAMEWORK-INTEGRATION-PATTERNS.md) | Real-world production implementation examples |
| 📖 **Overview** | [README](README.md) | Complete introduction and feature overview |

---

## 📖 Core Documentation (Foundation)

### 1. Getting Started

**[01-INSTALLATION-SETUP.md](01-INSTALLATION-SETUP.md)** (504 lines)
- Installation (npm, yarn, pnpm)
- Environment variable configuration
- TypeScript setup
- Client initialization
- Multiple client instances
- Configuration options reference
- Timeout and header customization
- Setup validation and testing

**Topics Covered:**
- Prerequisites
- Installation methods
- Environment variables (`ANTHROPIC_API_KEY`)
- TypeScript configuration (`tsconfig.json`)
- Client patterns (basic, validated, multi-tenant)
- Configuration options table
- Troubleshooting common issues

---

### 2. Messages API (Core Functionality)

**[02-MESSAGES-API.md](02-MESSAGES-API.md)** (787 lines)
- Message structure and types
- Creating messages
- System prompts
- Multi-turn conversations
- Content blocks (text, images, documents)
- Model selection and configuration
- Sampling parameters (temperature, top_p, top_k)
- Token limits and estimation
- Response structure and parsing
- Usage tracking

**Topics Covered:**
- `MessageParam` type structure
- Basic message creation
- System prompts (simple + advanced examples)
- Conversation history management
- Content block types (text, image, PDF)
- Model selection guide (Sonnet 4.5, Opus 4, Haiku 4.5)
- Temperature and creativity controls
- `max_tokens` configuration
- Response extraction patterns
- Token usage tracking and cost calculation
- Stop sequences
- Metadata tracking

---

### 3. Streaming Responses (Real-Time)

**[03-STREAMING.md](03-STREAMING.md)** (2,794 words)
- Why use streaming (UX benefits)
- Stream approaches (`.stream` helper vs `stream: true`)
- Stream event types (6 event types)
- Handling stream events
- Canceling streams (break, AbortController)
- Error handling in streams
- Next.js App Router SSE pattern
- React hooks for streaming
- Backpressure management
- Testing streaming responses

**Topics Covered:**
- Streaming vs. blocking requests
- `.stream` helper method (recommended)
- `stream: true` flag approach
- Event types: `message_start`, `content_block_start`, `content_block_delta`, etc.
- Text extraction from deltas
- Stream cancellation patterns
- Error recovery in streams
- Server-Sent Events (SSE) in Next.js
- `useStreamingAI` React hook
- Throttling and batching
- Mock streaming for tests

---

### 4. Error Handling (Production-Grade)

**[04-ERROR-HANDLING.md](04-ERROR-HANDLING.md)** (2,963 words)
- Error hierarchy (8 error classes)
- HTTP status codes (400, 401, 429, 500, 529)
- Retry strategies (exponential backoff, jitter)
- Rate limit handling (429 errors)
- Timeout handling
- Network errors
- Validation errors
- Authentication errors
- Server errors (overloaded)
- Circuit breaker pattern
- Logging and monitoring
- User-friendly error messages
- Error boundary patterns

**Topics Covered:**
- `APIError` class hierarchy
- Status code reference table
- Exponential backoff implementation
- Retry-after header parsing
- AbortController for timeouts
- Network resilience patterns
- Zod validation integration
- API key validation
- 500/529 handling strategies
- Circuit breaker implementation
- Structured error logging
- Error-to-message mapping
- Custom error handler classes

---

## 🎓 Advanced Topics

### 5. Prompt Engineering (Effective Prompting)

**[05-PROMPT-ENGINEERING.md](05-PROMPT-ENGINEERING.md)** (2,963 words)
- System prompt design
- Message role patterns
- Few-shot examples (0-5 shot)
- Chain-of-thought prompting
- XML tag usage
- Context window management (200K tokens)
- Response formatting
- Common pitfalls
- Advanced system prompt examples
- Extracting structured data
- Handling ambiguous inputs
- Multi-stage conversations

**Topics Covered:**
- System prompt structure (role, personality, constraints)
- User/assistant alternation rules
- Few-shot pattern selection
- Step-by-step reasoning techniques
- XML tags (`<thinking>`, `<answer>`, etc.)
- Context window strategies (200K for Sonnet 4.5)
- JSON/markdown response formatting
- Vague instruction pitfalls
- Complex system prompt patterns (2000+ tokens)
- Regex + validation for data extraction
- Clarification loop patterns
- Phase-based conversation tracking

---

### 6. Rate Limiting (Quota Management)

**[06-RATE-LIMITING.md](06-RATE-LIMITING.md)** (2,406 words)
- Rate limit tiers (Free, Standard, Pro, Scale)
- Token limits (TPM for input/output)
- Request limits (RPM)
- Response headers parsing
- Monitoring usage
- Retry with backoff
- Queue systems
- Prompt caching for rate limits
- Usage tracking patterns
- Cost estimation
- Alert thresholds

**Topics Covered:**
- Tier comparison table (limits and pricing)
- Claude Sonnet 4.5 limits (30K input TPM, 8K output TPM, 50 RPM)
- Rate limit header extraction
- Real-time quota monitoring
- 429 error handling with exponential backoff
- In-memory request queue
- Priority queue implementation
- Cache-aware token counting (90% savings)
- Session-level usage tracking
- Daily/monthly cost projections
- Warning/critical threshold alerts

---

### 7. Token Management (Cost Optimization)

**[07-TOKEN-MANAGEMENT.md](07-TOKEN-MANAGEMENT.md)** (2,821 words)
- Token counting basics (1 token ≈ 4 chars)
- Estimating tokens before requests
- Usage tracking from responses
- Prompt caching (90% savings)
- Cache TTL (5 minutes)
- Cache-aware rate limits
- System prompt caching pattern
- Context trimming strategies
- Cost calculation (pricing tiers)
- Budget alerts
- Token tracking patterns
- Optimization strategies

**Topics Covered:**
- Token estimation functions
- Real-time usage tracker
- Session-level token tracking
- Prompt caching strategies (system prompt, conversation history)
- Cache TTL management (5-minute window)
- Cached vs. uncached token counting
- System prompt caching patterns
- Simple vs. smart context trimming
- Cost calculation: $3/M input, $15/M output, $0.30/M cached
- Budget tracking with alerts
- Database-backed token analytics
- 6 key optimization strategies

---

## 🔧 Reference Documentation

### Quick Reference Card

**[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** (214 lines)
- Installation command
- Basic client setup
- Common message patterns
- Streaming basics
- Error handling snippets
- Type imports
- Token usage access
- Rate limit headers
- Retry logic
- Model configuration

**Use this for:**
- Fast lookup during coding
- Copy-paste ready snippets
- Common parameter values
- Quick error handling patterns

---

### Comprehensive Guide

**[COMPREHENSIVE-GUIDE.md](COMPREHENSIVE-GUIDE.md)** (~1000 lines)
- Complete technical reference consolidating all topics
- Installation through production best practices
- ✅ Good vs ❌ Bad pattern comparisons throughout
- Common pitfalls sections for every topic
- Real-world integration examples
- Performance optimization strategies
- Cost management techniques
- Production deployment checklist

**Use this for:**
- Deep technical understanding
- Architecture decisions
- Production implementation
- Troubleshooting complex issues
- Complete topic coverage

---

### Integration Patterns

**[FRAMEWORK-INTEGRATION-PATTERNS.md](FRAMEWORK-INTEGRATION-PATTERNS.md)** (599 lines)
- AI agent integration (class-based)
- Configuration management (DB + defaults)
- Multi-turn conversation with state
- Message persistence (Prisma)
- Type-safe API route handlers
- File attachments (PDF processing)
- Error handling strategy (3-tier)
- Logging integration
- Metrics extraction
- Progress tracking
- Testing patterns (Jest mocking)

**Use this for:**
- Real-world production code
- Production architecture patterns
- Integration with Prisma, Zod, Next.js
- Complete AI agent implementation
- Complete working examples

---

## 🗂️ Documentation by Use Case

### I want to...

#### Get Started
1. Read [README](README.md) for overview
2. Follow [01-INSTALLATION-SETUP.md](01-INSTALLATION-SETUP.md)
3. Review [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
4. Try examples from [02-MESSAGES-API.md](02-MESSAGES-API.md)

#### Build a Conversational Agent
1. Study [FRAMEWORK-INTEGRATION-PATTERNS.md](FRAMEWORK-INTEGRATION-PATTERNS.md) (AI agent patterns)
2. Learn [02-MESSAGES-API.md](02-MESSAGES-API.md) (multi-turn conversations)
3. Master [05-PROMPT-ENGINEERING.md](05-PROMPT-ENGINEERING.md) (system prompts)
4. Implement [03-STREAMING.md](03-STREAMING.md) (real-time responses)

#### Handle Errors Properly
1. Read [04-ERROR-HANDLING.md](04-ERROR-HANDLING.md)
2. Implement retry logic (exponential backoff)
3. Add circuit breaker pattern
4. Set up error monitoring

#### Optimize Costs
1. Study [07-TOKEN-MANAGEMENT.md](07-TOKEN-MANAGEMENT.md)
2. Implement prompt caching
3. Use context trimming strategies
4. Monitor with [06-RATE-LIMITING.md](06-RATE-LIMITING.md)

#### Stream Responses
1. Read [03-STREAMING.md](03-STREAMING.md)
2. Choose `.stream` helper (recommended)
3. Implement Next.js SSE pattern
4. Add React hook for UI integration

#### Write Better Prompts
1. Read [05-PROMPT-ENGINEERING.md](05-PROMPT-ENGINEERING.md)
2. Study advanced system prompt patterns
3. Use XML tags for structure
4. Implement few-shot examples

#### Manage Rate Limits
1. Read [06-RATE-LIMITING.md](06-RATE-LIMITING.md)
2. Parse response headers
3. Implement request queue
4. Set up usage monitoring

#### Test My Integration
1. See [FRAMEWORK-INTEGRATION-PATTERNS.md](FRAMEWORK-INTEGRATION-PATTERNS.md) (testing patterns)
2. Mock Anthropic client
3. Test streaming responses
4. Validate error handling

---

## 📊 Documentation Statistics

| Metric | Count |
|--------|-------|
| **Total Articles** | 12 (7 core + 5 reference) |
| **Total Lines** | ~8,000+ |
| **Total Words** | ~30,000+ |
| **Code Examples** | 200+ |
| **Tables** | 35+ |
| **TypeScript Types** | 50+ |
| **✅ /❌ Patterns** | 40+ |

---

## 🔗 External Resources

### Official Documentation
- **Anthropic SDK GitHub**: https://github.com/anthropics/anthropic-sdk-typescript
- **Claude API Docs**: https://docs.claude.com/
- **Prompt Engineering Guide**: https://docs.claude.com/en/docs/build-with-claude/prompt-engineering
- **Rate Limits**: https://docs.claude.com/en/api/rate-limits
- **API Reference**: https://docs.claude.com/en/api

### Related Knowledge Base Topics
- **TypeScript Patterns**: [`docs/kb/typescript/`](../typescript/)
- **Testing Patterns**: [`docs/kb/testing/`](../testing/)
- **API Design**: [`docs/kb/nextjs/`](../nextjs/)

---

## 🎯 Reading Paths

### Beginner Path (Start Here)
1. [README](README.md) - Overview
2. [01-INSTALLATION-SETUP.md](01-INSTALLATION-SETUP.md) - Setup
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Common patterns
4. [02-MESSAGES-API.md](02-MESSAGES-API.md) - Core API
5. [FRAMEWORK-INTEGRATION-PATTERNS.md](FRAMEWORK-INTEGRATION-PATTERNS.md) - Integration examples

### Advanced Path (Production)
1. [04-ERROR-HANDLING.md](04-ERROR-HANDLING.md) - Production errors
2. [06-RATE-LIMITING.md](06-RATE-LIMITING.md) - Quotas
3. [07-TOKEN-MANAGEMENT.md](07-TOKEN-MANAGEMENT.md) - Cost optimization
4. [03-STREAMING.md](03-STREAMING.md) - Real-time responses
5. [05-PROMPT-ENGINEERING.md](05-PROMPT-ENGINEERING.md) - Better prompts

### Reference Path (Quick Lookup)
1. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Fast lookup
2. Use INDEX.md (this file) to find specific topics
3. Jump to relevant sections in detailed articles

---

## 🏷️ Topic Tags

**Setup & Configuration:**
- [01-INSTALLATION-SETUP.md](01-INSTALLATION-SETUP.md)
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md)

**Core API:**
- [02-MESSAGES-API.md](02-MESSAGES-API.md)
- [03-STREAMING.md](03-STREAMING.md)

**Production Readiness:**
- [04-ERROR-HANDLING.md](04-ERROR-HANDLING.md)
- [06-RATE-LIMITING.md](06-RATE-LIMITING.md)
- [07-TOKEN-MANAGEMENT.md](07-TOKEN-MANAGEMENT.md)

**Best Practices:**
- [05-PROMPT-ENGINEERING.md](05-PROMPT-ENGINEERING.md)
- [FRAMEWORK-INTEGRATION-PATTERNS.md](FRAMEWORK-INTEGRATION-PATTERNS.md)

**Reference:**
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- [README](README.md)
- [INDEX](INDEX.md) (this file)

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.1 | 2025-11-13 | Corrected SDK version to 0.27.3, removed references to non-existent files |
| 1.0.0 | 2025-11-11 | Initial KB creation with comprehensive articles |

---

## 📝 Contributing

When updating this knowledge base:

1. **Maintain Structure**: Follow existing numbering (01, 02, etc.)
2. **Include Examples**: Add TypeScript code examples
3. **Cross-Reference**: Link related articles
4. **Update Index**: Add new articles to this INDEX.md
5. **Test Code**: Verify all code examples work
6. **Integration Patterns**: Add real examples to `FRAMEWORK-INTEGRATION-PATTERNS.md`

---

## ❓ Support

**Can't find what you need?**

1. Search this INDEX for keywords
2. Check [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
3. Review [Official Anthropic Docs](https://docs.claude.com/)
4. Check your project's development resources

---

**SDK Supported:** @anthropic-ai/sdk 0.27.3
**Claude Model:** claude-sonnet-4-5-20250929
**Status:** Production Ready ✅
