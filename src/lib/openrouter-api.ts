/**
 * OpenRouter API integration
 * Uses the free model: meta-llama/llama-3.2-3b-instruct:free
 */

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
 * Create a system prompt for the flight booking assistant
 */
export function getSystemPrompt(): string {
  return `You are a helpful flight booking assistant. You can help users with:
- Finding and booking flights
- Seat selection
- Payment and add-ons
- Managing their bookings
- General travel questions

Be friendly, concise, and helpful. If users ask about specific bookings or flights, 
guide them to use the appropriate features in the application.`;
}
