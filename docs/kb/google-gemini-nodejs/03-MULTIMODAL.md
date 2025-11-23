---
id: google-gemini-nodejs-03-multimodal
topic: google-gemini-nodejs
file_role: core
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [google-gemini-fundamentals, google-gemini-messages-api]
related_topics: [google-gemini, multimodal-ai, image-analysis, video-processing]
embedding_keywords: [google-gemini, multimodal, image-analysis, video-processing, audio-transcription, pdf-parsing]
last_reviewed: 2025-11-13
---

# Gemini Multimodal Capabilities

**Purpose**: Master image, audio, video, and document processing with Gemini's native multimodal capabilities.

---

## 1. Image Analysis

### Basic Image Analysis

```typescript
import fs from 'fs';

const imagePart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('image.jpg')).toString('base64'),
    mimeType: 'image/jpeg',
  },
};

const result = await model.generateContent([
  'What is in this image? Describe in detail.',
  imagePart,
]);

console.log(result.response.text());
```

### Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- HEIC (.heic)
- HEIF (.heif)

**Max Size**: 20MB per image

---

## 2. Multiple Images

### Compare Images

```typescript
const image1 = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('before.png')).toString('base64'),
    mimeType: 'image/png',
  },
};

const image2 = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('after.png')).toString('base64'),
    mimeType: 'image/png',
  },
};

const result = await model.generateContent([
  'Compare these two images and identify the differences:',
  'Image 1 (Before):',
  image1,
  'Image 2 (After):',
  image2,
]);
```

### Analyze Chart/Graph

```typescript
const chartImage = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('chart.png')).toString('base64'),
    mimeType: 'image/png',
  },
};

const result = await model.generateContent([
  `Analyze this chart and provide:
  1. Main trends
  2. Key data points
  3. Insights and recommendations`,
  chartImage,
]);
```

---

## 3. Audio Processing

### Audio Transcription

```typescript
const audioPart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('audio.mp3')).toString('base64'),
    mimeType: 'audio/mp3',
  },
};

const result = await model.generateContent([
  'Transcribe this audio and summarize the main points:',
  audioPart,
]);
```

### Supported Audio Formats

- WAV (.wav)
- MP3 (.mp3)
- AIFF (.aiff)
- AAC (.aac)
- OGG Vorbis (.ogg)
- FLAC (.flac)

**Max Duration**: 9.5 hours
**Max Size**: 2GB

---

## 4. Video Analysis

### Basic Video Analysis

```typescript
const videoPart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('video.mp4')).toString('base64'),
    mimeType: 'video/mp4',
  },
};

const result = await model.generateContent([
  'Describe what happens in this video',
  videoPart,
]);
```

### Video Summarization

```typescript
const result = await model.generateContent([
  `Analyze this video and provide:
  1. Summary of content
  2. Key moments (with timestamps)
  3. Main themes
  4. Action items (if applicable)`,
  videoPart,
]);
```

### Supported Video Formats

- MP4 (.mp4)
- MPEG (.mpeg)
- MOV (.mov)
- AVI (.avi)
- FLV (.flv)
- MPG (.mpg)
- WebM (.webm)
- WMV (.wmv)
- 3GPP (.3gpp)

**Max Duration**: 1 hour
**Max Size**: 2GB

---

## 5. PDF Documents

### PDF Text Extraction

```typescript
const pdfPart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('document.pdf')).toString('base64'),
    mimeType: 'application/pdf',
  },
};

const result = await model.generateContent([
  'Summarize this PDF document in 3 key points:',
  pdfPart,
]);
```

### PDF with Images

Gemini can analyze both text and images in PDFs:

```typescript
const result = await model.generateContent([
  `Analyze this PDF and:
  1. Extract main text content
  2. Describe any charts or diagrams
  3. Identify key data points`,
  pdfPart,
]);
```

**Max Pages**: No official limit (depends on token count)
**Max Size**: 20MB

---

## 6. Mixed Multimodal Inputs

### Text + Image + Audio

```typescript
const imagePart = { /* ... */ };
const audioPart = { /* ... */ };

const result = await model.generateContent([
  'Context: This is a product review.',
  'Image of the product:',
  imagePart,
  'Audio review:',
  audioPart,
  'Please provide a summary combining visual and audio information.',
]);
```

---

## 7. Vertex AI File API (For Large Files)

For files > 20MB, use Vertex AI File API:

```typescript
import { VertexAI } from '@google-cloud/vertexai';

const vertexAI = new VertexAI({ project: 'your-project', location: 'us-central1' });
const model = vertexAI.getGenerativeModel({ model: 'gemini-1.5-pro' });

// Upload file to Cloud Storage first
const filePart = {
  fileData: {
    mimeType: 'video/mp4',
    fileUri: 'gs://your-bucket/large-video.mp4',
  },
};

const result = await model.generateContent(['Analyze this video', filePart]);
```

---

## 8. Best Practices

### Image Best Practices

- Use JPEG for photos, PNG for screenshots/diagrams
- Ensure good image quality (not blurry)
- Crop to relevant area to reduce token usage
- Use multiple images for comparison tasks

### Video Best Practices

- Keep videos < 10 minutes for faster processing
- Higher resolution = better analysis but more tokens
- Extract audio separately if you only need transcription
- Consider frame extraction for static analysis

### PDF Best Practices

- OCR quality matters - ensure readable text
- Complex layouts may not parse perfectly
- Consider extracting images separately for detailed analysis
- Split very large PDFs into chunks

---

## 9. Common Use Cases

### Use Case: Receipt/Invoice Processing

```typescript
const receiptImage = { /* ... */ };

const result = await model.generateContent([
  `Extract data from this receipt in JSON format:
  {
    "vendor": "...",
    "date": "YYYY-MM-DD",
    "total": 0.00,
    "items": [{"name": "...", "price": 0.00}]
  }`,
  receiptImage,
]);

const data = JSON.parse(result.response.text());
```

### Use Case: Meeting Notes from Recording

```typescript
const meetingAudio = { /* ... */ };

const result = await model.generateContent([
  `Transcribe this meeting and provide:
  1. Attendees mentioned
  2. Key discussion points
  3. Action items with owners
  4. Decisions made`,
  meetingAudio,
]);
```

### Use Case: UI Screenshot Analysis

```typescript
const screenshotImage = { /* ... */ };

const result = await model.generateContent([
  `Analyze this UI screenshot and provide:
  1. Main components visible
  2. UX/UI issues or improvements
  3. Accessibility concerns
  4. Suggested changes`,
  screenshotImage,
]);
```

---

## 10. AI Pair Programming Notes

### When to Load This File

- Building image analysis features
- Implementing video processing
- Creating transcription services
- Processing documents

### Key Takeaways

1. Gemini is natively multimodal - no separate models needed
2. Base64 encoding for inline data < 20MB
3. Use Vertex AI File API for larger files
4. Combine multiple modalities in single requests
5. Quality of input affects output quality

---

**Next**: [04-STREAMING.md](04-STREAMING.md) for real-time response generation.
