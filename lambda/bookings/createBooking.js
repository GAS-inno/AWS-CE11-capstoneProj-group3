const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { v4: uuidv4 } = require('uuid');

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const BOOKINGS_TABLE = process.env.BOOKINGS_TABLE;

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  // CORS headers
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'POST,OPTIONS'
  };

  // Handle preflight
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: ''
    };
  }

  try {
    // Parse request body
    const body = JSON.parse(event.body || '{}');
    
    // Validate required fields
    const requiredFields = ['user_id', 'flight_id', 'passenger_name', 'passenger_email', 'seat_number', 'total_amount'];
    for (const field of requiredFields) {
      if (!body[field]) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ 
            error: `Missing required field: ${field}` 
          })
        };
      }
    }

    // Create booking object
    const bookingId = uuidv4();
    const now = new Date().toISOString();
    
    const booking = {
      id: bookingId,
      user_id: body.user_id,
      flight_id: body.flight_id,
      passenger_name: body.passenger_name,
      passenger_email: body.passenger_email,
      seat_number: body.seat_number,
      booking_status: body.booking_status || 'confirmed',
      total_amount: parseFloat(body.total_amount),
      booking_date: body.booking_date || now,
      created_at: now,
      // Optional fields
      ...(body.flight_details && { flight_details: body.flight_details }),
      ...(body.return_flight_id && { return_flight_id: body.return_flight_id }),
      ...(body.return_seat_number && { return_seat_number: body.return_seat_number }),
      ...(body.return_flight_details && { return_flight_details: body.return_flight_details })
    };

    // Save to DynamoDB
    const command = new PutCommand({
      TableName: BOOKINGS_TABLE,
      Item: booking
    });

    await ddbDocClient.send(command);

    console.log('Booking created:', bookingId);

    return {
      statusCode: 201,
      headers,
      body: JSON.stringify({
        message: 'Booking created successfully',
        booking: booking
      })
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Failed to create booking',
        details: error.message 
      })
    };
  }
};
