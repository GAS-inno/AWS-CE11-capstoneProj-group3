/**
 * Lambda function to proxy OpenRouter API requests
 * Keeps the API key secure on the server side
 */

const https = require('https');

const OPENROUTER_API_URL = 'openrouter.ai';
const OPENROUTER_PATH = '/api/v1/chat/completions';
const FREE_MODEL = 'meta-llama/llama-3.2-3b-instruct:free';

/**
 * Make HTTPS request to OpenRouter API
 */
function callOpenRouterAPI(messages, apiKey) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      model: FREE_MODEL,
      messages: messages,
      temperature: 0.7,
      max_tokens: 800,
    });

    const options = {
      hostname: OPENROUTER_API_URL,
      port: 443,
      path: OPENROUTER_PATH,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'HTTP-Referer': process.env.SITE_URL || 'https://sky-high-booker.com',
        'X-Title': 'Flight Booking Assistant',
      },
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch (error) {
            reject(new Error(`Failed to parse response: ${error.message}`));
          }
        } else {
          reject(new Error(`OpenRouter API error: ${res.statusCode} - ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Lambda handler
 */
exports.handler = async (event) => {
  console.log('Chatbot proxy request:', JSON.stringify(event, null, 2));

  // CORS headers
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'POST,OPTIONS',
  };

  // Handle OPTIONS request for CORS preflight
  if (event.httpMethod === 'OPTIONS' || event.requestContext?.http?.method === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }

  try {
    // Get API key from environment
    const apiKey = process.env.OPENROUTER_API_KEY;
    if (!apiKey) {
      console.error('OPENROUTER_API_KEY not configured');
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          error: 'API key not configured',
        }),
      };
    }

    // Parse request body
    let body;
    try {
      body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    } catch (error) {
      console.error('Invalid JSON in request body:', error);
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: 'Invalid request body',
        }),
      };
    }

    // Validate messages
    if (!body.messages || !Array.isArray(body.messages)) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: 'Missing or invalid messages array',
        }),
      };
    }

    // Call OpenRouter API
    console.log('Calling OpenRouter API with', body.messages.length, 'messages');
    const response = await callOpenRouterAPI(body.messages, apiKey);

    // Return response
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify(response),
    };

  } catch (error) {
    console.error('Error in chatbot proxy:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error.message || 'Internal server error',
      }),
    };
  }
};
