const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");
const { v4: uuidv4 } = require('uuid');

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);
const snsClient = new SNSClient({});

const BOOKINGS_TABLE = process.env.BOOKINGS_TABLE;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;

// CORS headers
const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'POST,OPTIONS'
};

exports.handler = async (event) => {
  try {
    console.log('Event:', JSON.stringify(event, null, 2));
    console.log('BOOKINGS_TABLE:', BOOKINGS_TABLE);

    // Handle preflight
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers,
        body: ''
      };
    }
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

    if (SNS_TOPIC_ARN) {
      try {
        const contentLines = [
          `Booking created: ${bookingId}`,
          `Passenger: ${booking.passenger_name} (${booking.passenger_email})`,
          `Flight: ${booking.flight_id}`,
          `Seat: ${booking.seat_number}`,
          `Total: ${booking.total_amount}`,
        ];

        await snsClient.send(
          new PublishCommand({
            TopicArn: SNS_TOPIC_ARN,
            Message: JSON.stringify({ content: contentLines.join("\n") }),
          })
        );

        console.log('Published booking notification to SNS');
      } catch (notifyError) {
        console.warn('Failed to publish SNS notification:', notifyError);
      }
    } else {
      console.log('SNS_TOPIC_ARN not set; skipping notification');
    }

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
    console.error('Error stack:', error.stack);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Failed to create booking',
        details: error.message,
        table: BOOKINGS_TABLE || 'BOOKINGS_TABLE not set'
      })
    };
  }
};
