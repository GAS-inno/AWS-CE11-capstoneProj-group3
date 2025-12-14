# OpenRouter Chatbot Integration

This application includes an AI-powered chatbot using OpenRouter's free model (Meta Llama 3.2 3B Instruct).

## Setup Instructions

### 1. Get Your OpenRouter API Key

1. Go to [OpenRouter](https://openrouter.ai/)
2. Sign up or log in
3. Navigate to [Keys](https://openrouter.ai/keys)
4. Create a new API key

### 2. Configure Environment Variables

#### For Local Development:

Create a `.env.local` file in the root directory:

```bash
VITE_OPENROUTER_API_KEY=your_api_key_here
```

#### For GitHub Actions / Deployment:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add:
   - Name: `VITE_OPENROUTER_API_KEY`
   - Value: Your OpenRouter API key

### 3. For Build/Deployment

If you're using GitHub Actions or another CI/CD pipeline, make sure to pass the environment variable during the build:

```yaml
- name: Build
  run: npm run build
  env:
    VITE_OPENROUTER_API_KEY: ${{ secrets.VITE_OPENROUTER_API_KEY }}
```

## Features

- **Free Model**: Uses Meta Llama 3.2 3B Instruct (free tier)
- **Floating Chat Button**: Accessible from any page in the application
- **Context-Aware**: Configured as a flight booking assistant
- **Persistent Chat**: Chat history maintained during the session
- **Responsive UI**: Works on all screen sizes

## Usage

Once configured, a floating chat button will appear in the bottom-right corner of your application. Click it to open the chatbot and start chatting!

## Model Information

- **Model**: `meta-llama/llama-3.2-3b-instruct:free`
- **Cost**: Free
- **Rate Limits**: Subject to OpenRouter's free tier limits
- **Max Tokens**: 500 per response (configurable in `src/lib/openrouter-api.ts`)

## Customization

You can customize the chatbot behavior by editing:
- **System Prompt**: In `src/lib/openrouter-api.ts` → `getSystemPrompt()`
- **UI Styling**: In `src/components/Chatbot.tsx`
- **Model Settings**: In `src/lib/openrouter-api.ts` → `sendChatMessage()` function

## Alternative Free Models

You can switch to other free models by changing the `FREE_MODEL` constant in `src/lib/openrouter-api.ts`:

- `meta-llama/llama-3.2-3b-instruct:free`
- `meta-llama/llama-3.2-1b-instruct:free`
- `google/gemma-2-9b-it:free`
- `nousresearch/hermes-3-llama-3.1-405b:free`

Check [OpenRouter Models](https://openrouter.ai/models?order=newest&supported_parameters=tools&max_price=0) for the latest free models.
