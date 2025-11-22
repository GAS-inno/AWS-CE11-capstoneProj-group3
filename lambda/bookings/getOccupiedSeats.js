const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, QueryCommand, ScanCommand } = require("@aws-sdk/lib-dynamodb");

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
    // Get flight_id and date from query parameters
    const flightId = event.queryStringParameters?.flight_id;
    const departureDate = event.queryStringParameters?.departure_date;

    if (!flightId) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'flight_id is required' })
      };
    }

    // Query bookings by flight_id using FlightBookingsIndex GSI
    const queryParams = {
      TableName: BOOKINGS_TABLE,
      IndexName: 'FlightBookingsIndex',
      KeyConditionExpression: 'flight_id = :flightId',
      ExpressionAttributeValues: {
        ':flightId': flightId
      }
    };

    // If departure_date is provided, filter by it
    if (departureDate) {
      queryParams.FilterExpression = 'flight_details.departure_date = :departureDate';
      queryParams.ExpressionAttributeValues[':departureDate'] = departureDate;
    }

    const command = new QueryCommand(queryParams);
    const result = await ddbDocClient.send(command);

    // Also scan for ALL bookings where this flight appears as return_flight_id
    // This includes round-trip bookings where someone else selected this flight as their return
    const scanParams = {
      TableName: BOOKINGS_TABLE,
      FilterExpression: 'return_flight_id = :flightId',
      ExpressionAttributeValues: {
        ':flightId': flightId
      }
    };

    // Filter by departure_date for return flights if provided
    if (departureDate) {
      scanParams.FilterExpression += ' AND return_flight_details.departure_date = :departureDate';
      scanParams.ExpressionAttributeValues[':departureDate'] = departureDate;
    }

    const scanCommand = new ScanCommand(scanParams);
    const returnFlightResult = await ddbDocClient.send(scanCommand);

    console.log('Outbound bookings (flight_id):', result.Items?.length || 0);
    console.log('Return bookings (return_flight_id):', returnFlightResult.Items?.length || 0);

    // Extract occupied seats from bookings
    const occupiedSeats = [];
    
    // Add seats from main flight bookings
    if (result.Items) {
      for (const booking of result.Items) {
        if (booking.seat_number) {
          occupiedSeats.push(booking.seat_number);
        }
      }
    }
    
    // Add seats from return flight bookings
    if (returnFlightResult.Items) {
      for (const booking of returnFlightResult.Items) {
        if (booking.return_seat_number) {
          occupiedSeats.push(booking.return_seat_number);
        }
      }
    }

    // Remove duplicates
    const uniqueOccupiedSeats = [...new Set(occupiedSeats)];

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        occupied_seats: uniqueOccupiedSeats,
        count: uniqueOccupiedSeats.length
      })
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Failed to fetch occupied seats',
        details: error.message 
      })
    };
  }
};
