const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const BOOKINGS_TABLE = process.env.BOOKINGS_TABLE;

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,OPTIONS'
  };

  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: ''
    };
  }

  try {
    // Get booking ID from path parameters
    const bookingId = event.pathParameters?.id;

    if (!bookingId) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'booking ID is required' })
      };
    }

    // Get booking from DynamoDB
    const command = new GetCommand({
      TableName: BOOKINGS_TABLE,
      Key: {
        id: bookingId
      }
    });

    const result = await ddbDocClient.send(command);

    if (!result.Item) {
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ error: 'Booking not found' })
      };
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        booking: result.Item
      })
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Failed to fetch booking',
        details: error.message 
      })
    };
  }
};
