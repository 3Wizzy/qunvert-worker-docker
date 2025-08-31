# Chatbot Implementation Setup Guide

## Overview
The chatbot processor has been successfully implemented in the qunvert-worker-docker! This worker now supports:

✅ **Keyword-based responses** with exact and broad matching  
✅ **Media handling** - First media with caption, then remaining media separately  
✅ **AI fallback** when no keywords match  
✅ **Real-time message processing** when sessions are assigned to chatbots  

## Configuration Required

### Environment Variables
Make sure your `.env` file contains:

```bash
# Worker Identity
WORKER_ID=worker-1
WORKER_URL=http://localhost:3000
MAX_SESSIONS=10

# Main API Connection
QUNVERT_API_URL=http://localhost:10010/api
API_KEY=SECRETE_API_KEY_QUNVERT

# WhatsApp Manager
WHATSAPP_MANAGER_URL=http://localhost:10020
BASE_WEBHOOK_URL=http://localhost:10020/webhook

# Session Storage
SESSIONS_PATH=./sessions
SET_MESSAGES_AS_SEEN=true
```

## How It Works

### 1. Session Assignment
- When you assign a chatbot to a WhatsApp session in the main interface
- The worker automatically fetches the assignment via `/api/chatbots/assignments/{workerId}`
- Chatbot items and keywords are loaded into memory

### 2. Message Processing
- Incoming messages are processed in real-time
- Keyword matching happens first (exact or broad match)
- If match found → sends response + media files
- If no match → falls back to AI response

### 3. Media Handling
- **First media file**: Sent with the caption text
- **Additional media files**: Sent individually without caption
- Supports images, audio, video, and documents from Cloudflare URLs

### 4. AI Fallback
- Uses OpenAI integration from main API
- Provides contextual responses based on chatbot configuration
- Graceful fallback if AI service is unavailable

## API Endpoints Added

### Worker Endpoints
- `GET /chatbot/status` - View chatbot processor status
- `POST /chatbot/refresh` - Force refresh chatbot assignments  
- `GET /chatbot/session/{sessionId}` - Get specific session assignment
- `POST /chatbot/test/{sessionId}` - Test keyword matching

### Main API Endpoints
- `GET /api/chatbots/assignments/{workerId}` - Get assignments for worker
- `POST /api/chatbots/ai/generate-response` - AI response generation

## Testing Your Setup

### 1. Start the Services
```bash
# Main API (Qunvert_back)
npm start

# WhatsApp Manager 
npm run start-wa-manager

# Worker (qunvert-worker-docker)
npm start
```

### 2. Check Worker Status
```bash
curl -H "x-api-key: YOUR_API_KEY" http://localhost:3000/chatbot/status
```

### 3. Assign Chatbot to Session
- Use the main interface to assign a chatbot to a WhatsApp session
- The worker will automatically detect the assignment within 30 seconds

### 4. Test Message Flow
Send a test message that matches a keyword in your chatbot:
```bash
curl -H "x-api-key: YOUR_API_KEY" \
  -X POST http://localhost:3000/chatbot/test/SESSION_ID \
  -d '{"message": "your test keyword"}'
```

## Troubleshooting

### Worker Not Getting Assignments (401 Errors)
If you see `🤖 [CHATBOT] Error refreshing chatbot assignments: Request failed with status code 401`:

1. **Check API Key**: Ensure `API_KEY=SECRETE_API_KEY_QUNVERT` in worker `.env`
2. **Verify API URL**: Check `QUNVERT_API_URL` points to main API
3. **Check Worker ID**: Verify `WORKER_ID` matches what's registered with manager
4. **Test API Connection**: 
   ```bash
   curl -H "x-api-key: SECRETE_API_KEY_QUNVERT" \
     http://localhost:10010/api/chatbots/assignments/worker-1
   ```

### Worker Not Getting Assignments (Other Issues)
1. Check `WORKER_ID` matches what's registered with manager
2. Verify `QUNVERT_API_URL` points to main API
3. Ensure API key is correct
4. Check logs for connection errors

### Messages Not Being Processed  
1. Verify session is connected and assigned to chatbot
2. Check chatbot has active items with keywords
3. Look for processing errors in worker logs
4. Test keyword matching via API endpoint

### Media Not Sending
1. Verify Cloudflare URLs are accessible
2. Check network connectivity from worker
3. Ensure file types are supported
4. Look for media download errors in logs

### AI Fallback Not Working
1. Check OpenAI API key in main backend
2. Verify `/api/chatbots/ai/generate-response` endpoint
3. Look for AI service errors in main API logs

## Architecture Summary

```
WhatsApp Message → Worker Session → Chatbot Processor
                                        ↓
                     Keyword Match? → Send Item Response + Media
                                        ↓ (if no match)
                     AI Service ← Main API ← Generate AI Response
```

The implementation provides a complete chatbot solution with intelligent keyword matching, rich media support, and AI-powered fallback responses!
