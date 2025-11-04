const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, QueryCommand } = require("@aws-sdk/lib-dynamodb");

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
    // Get user_id from query parameters
    const userId = event.queryStringParameters?.user_id;

    if (!userId) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'user_id is required' })
      };
    }

    // Query bookings by user_id using GSI
    const command = new QueryCommand({
      TableName: BOOKINGS_TABLE,
      IndexName: 'UserBookingsIndex',
      KeyConditionExpression: 'user_id = :userId',
      ExpressionAttributeValues: {
        ':userId': userId
      },
      ScanIndexForward: false // Sort by booking_date descending (newest first)
    });

    const result = await ddbDocClient.send(command);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        bookings: result.Items || [],
        count: result.Count
      })
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Failed to fetch bookings',
        details: error.message 
      })
    };
  }
};
