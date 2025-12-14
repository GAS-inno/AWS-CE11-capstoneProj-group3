/**
 * OpenRouter API integration
 * Uses the free model: meta-llama/llama-3.2-3b-instruct:free
 */

import { formatContextForPrompt } from './chatbot-context';

const OPENROUTER_API_URL = 'https://openrouter.ai/api/v1/chat/completions';
const FREE_MODEL = 'meta-llama/llama-3.2-3b-instruct:free';

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface ChatResponse {
  id: string;
  choices: {
    message: {
      role: string;
      content: string;
    };
    finish_reason: string;
  }[];
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

/**
 * Send a chat message to OpenRouter API
 * @param messages - Array of chat messages in the conversation
 * @param apiKey - OpenRouter API key (from environment variable)
 * @returns Response from the AI model
 */
export async function sendChatMessage(
  messages: ChatMessage[],
  apiKey: string
): Promise<string> {
  try {
    const response = await fetch(OPENROUTER_API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': window.location.origin,
        'X-Title': 'Flight Booking Assistant',
      },
      body: JSON.stringify({
        model: FREE_MODEL,
        messages: messages,
        temperature: 0.7,
        max_tokens: 500,
      }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(
        `OpenRouter API error: ${response.status} - ${errorData.error?.message || response.statusText}`
      );
    }

    const data: ChatResponse = await response.json();
    
    if (!data.choices || data.choices.length === 0) {
      throw new Error('No response from AI model');
    }

    return data.choices[0].message.content;
  } catch (error) {
    console.error('Error calling OpenRouter API:', error);
    throw error;
  }
}

/**
 * Create a system prompt for the flight booking assistant with project context
 */
export function getSystemPrompt(): string {
  const contextInfo = formatContextForPrompt();
  
  return `You are a helpful flight booking assistant for Sky High Booker, a flight booking application.

**About the Application:**
Sky High Booker is a modern flight booking platform built with React, AWS, and Terraform that allows users to:
- Search and book flights between major airports
- Select seats on their flights
- Add extras like meals, baggage, and travel insurance
- Make secure payments
- Manage their bookings

**Features Available:**
1. **Flight Search** - Search flights by origin, destination, and date
2. **Seat Selection** - Choose your preferred seat (window, aisle, or middle)
3. **Add-ons** - Add meals, extra baggage, or travel insurance
4. **Payment** - Secure payment processing
5. **My Bookings** - View and manage existing bookings
6. **User Profile** - Manage account settings

**Technical Stack:**
- Frontend: React with TypeScript, Vite, Tailwind CSS
- Backend: AWS Lambda functions
- Database: DynamoDB (flights, bookings, payments tables)
- Authentication: AWS Cognito
- API: AWS API Gateway
- Hosting: S3 + CloudFront CDN

${contextInfo}

**How to Help Users:**
- Guide them to search for flights using the search form on the homepage
- Explain the booking process: Search → Select Flight → Choose Seat → Add-ons → Payment → Confirmation
- Help with account-related questions (they need to sign in for bookings)
- For specific flight availability or pricing, encourage them to use the search feature
- For technical issues, suggest checking their connection or contacting support

Be friendly, concise, and helpful. Provide actionable guidance and direct users to the appropriate features in the application.`;
}
