/**
 * Context provider for chatbot to access flight and booking data
 * This gives the chatbot real-time information about available flights
 */

import { Flight, Booking } from './aws-dynamodb-api';

export interface ChatbotContext {
  availableRoutes: string[];
  airlines: string[];
  features: string[];
  currencies: string[];
}

/**
 * Get dynamic context about the current state of the application
 * This can be expanded to include real-time flight data, user's current search, etc.
 */
export function getChatbotContext(): ChatbotContext {
  return {
    availableRoutes: [
      'JFK (New York) ↔ LAX (Los Angeles)',
      'SIN (Singapore) ↔ JFK (New York)',
      'NRT (Tokyo) ↔ LAX (Los Angeles)',
      'LAX (Los Angeles) ↔ NRT (Tokyo)',
      'JFK (New York) ↔ SIN (Singapore)',
    ],
    airlines: [
      'SkyHigh Airlines',
      'AirConnect',
      'GlobalAir',
    ],
    features: [
      'Multi-currency support (USD, EUR, GBP, JPY, SGD)',
      'Real-time seat availability',
      'Meal selection (Vegetarian, Non-Vegetarian, Vegan)',
      'Extra baggage options',
      'Travel insurance',
      'Flexible booking management',
    ],
    currencies: ['USD', 'EUR', 'GBP', 'JPY', 'SGD'],
  };
}

/**
 * Format chatbot context for inclusion in AI prompts
 */
export function formatContextForPrompt(): string {
  const context = getChatbotContext();
  
  return `
**Current Available Routes:**
${context.availableRoutes.map(route => `- ${route}`).join('\n')}

**Partner Airlines:**
${context.airlines.map(airline => `- ${airline}`).join('\n')}

**Supported Currencies:**
${context.currencies.join(', ')}

**Key Features:**
${context.features.map(feature => `- ${feature}`).join('\n')}
`;
}

/**
 * Enhanced function to provide context-aware responses
 * This can be called before sending messages to include current app state
 */
export function enrichMessageWithContext(userMessage: string): string {
  const context = getChatbotContext();
  
  // Check if user is asking about routes/flights
  if (userMessage.toLowerCase().includes('route') || 
      userMessage.toLowerCase().includes('where') ||
      userMessage.toLowerCase().includes('fly to') ||
      userMessage.toLowerCase().includes('destination')) {
    return `${userMessage}\n\nContext: Our available routes are: ${context.availableRoutes.join(', ')}`;
  }
  
  // Check if user is asking about airlines
  if (userMessage.toLowerCase().includes('airline')) {
    return `${userMessage}\n\nContext: We partner with: ${context.airlines.join(', ')}`;
  }
  
  // Check if user is asking about payment/currency
  if (userMessage.toLowerCase().includes('currency') || 
      userMessage.toLowerCase().includes('payment') ||
      userMessage.toLowerCase().includes('price')) {
    return `${userMessage}\n\nContext: We support ${context.currencies.join(', ')} currencies`;
  }
  
  return userMessage;
}
