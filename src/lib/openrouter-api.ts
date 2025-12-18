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
        max_tokens: 800,
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
  return `You are a helpful flight booking assistant for Sky High Booker.

We offer flights between: JFK-LAX, SIN-JFK, NRT-LAX (and reverse routes)
Airlines: SkyHigh, AirConnect, GlobalAir
Currencies: USD, EUR, GBP, JPY, SGD

Features:
- Flight search and booking
- Seat selection (window, aisle, middle)
- Add-ons: meals, baggage, insurance
- Secure payments
- Booking management

Booking process: Search → Select Flight → Choose Seat → Add-ons → Payment → Confirmation

Users must sign in to make bookings. Guide them to use the search form for flight availability and pricing.

IMPORTANT: If you don't have information about something or if a question is outside your knowledge scope (like specific real-time prices, availability, or topics unrelated to flight booking), politely say "I don't have that specific information" or "I'm not sure about that, but I can help you with..." and redirect them to relevant features like the search form or My Bookings section.

Be friendly, concise, and helpful.`;
}
