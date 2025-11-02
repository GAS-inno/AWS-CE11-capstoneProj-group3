import { get, post, put, del } from '@aws-amplify/api'
import { getCurrentUser } from '@aws-amplify/auth'
import { v4 as uuidv4 } from 'uuid'

// API endpoint constants
const API_NAME = 'BookingAPI'

// Interfaces for our booking system (DynamoDB format)
export interface Flight {
  id: string
  route: string // "JFK-LAX" for indexing
  from_location: string
  to_location: string
  departure_time: string
  arrival_time: string
  departure_date: string // "YYYY-MM-DD" for indexing
  price: number
  airline: string
  flight_number: string
  duration: string
  aircraft: string
  available_seats: number
  created_at?: string
}

export interface Booking {
  id: string
  user_id: string
  flight_id: string
  passenger_name: string
  passenger_email: string
  seat_number: string
  booking_status: 'confirmed' | 'pending' | 'cancelled'
  total_amount: number
  booking_date: string // ISO string for sorting
  created_at?: string
  flight?: Flight
}

export interface Payment {
  id: string
  booking_id: string
  user_id: string
  payment_method: string
  payment_status: 'completed' | 'pending' | 'failed'
  amount: number
  currency: string
  transaction_id?: string
  payment_gateway?: string
  payment_date: string
  created_at?: string
}

export interface CreateBookingData {
  flight_id: string
  passenger_name: string
  passenger_email: string
  seat_number: string
  total_amount: number
}

class DynamoDBAWSAPIService {
  // Helper method to format dates for DynamoDB
  private formatDate(date: Date = new Date()): string {
    return date.toISOString()
  }

  private formatDateOnly(date: Date = new Date()): string {
    return date.toISOString().split('T')[0]
  }

  // Flights API
  async searchFlights(params: {
    from?: string
    to?: string
    departure_date?: string
    passengers?: number
  }): Promise<Flight[]> {
    try {
      const queryParams = new URLSearchParams()
      
      // If we have route info, use the RouteIndex for efficient querying
      if (params.from && params.to) {
        const route = `${params.from}-${params.to}`
        queryParams.append('route', route)
      }
      
      if (params.departure_date) {
        queryParams.append('departure_date', params.departure_date)
      }
      if (params.passengers) {
        queryParams.append('min_seats', params.passengers.toString())
      }

      const restOperation = get({
        apiName: API_NAME,
        path: `/flights${queryParams.toString() ? '?' + queryParams.toString() : ''}`,
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.flights || []
    } catch (error) {
      console.error('Error searching flights:', error)
      throw new Error('Failed to search flights')
    }
  }

  async getFlightById(flightId: string): Promise<Flight | null> {
    try {
      const restOperation = get({
        apiName: API_NAME,
        path: `/flights/${flightId}`,
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.flight || null
    } catch (error) {
      console.error('Error fetching flight:', error)
      throw new Error('Failed to fetch flight details')
    }
  }

  // Bookings API
  async createBooking(bookingData: CreateBookingData): Promise<Booking> {
    try {
      const user = await getCurrentUser()
      const bookingId = uuidv4()
      const now = this.formatDate()
      
      const booking: Omit<Booking, 'flight'> = {
        id: bookingId,
        user_id: user.userId,
        flight_id: bookingData.flight_id,
        passenger_name: bookingData.passenger_name,
        passenger_email: bookingData.passenger_email,
        seat_number: bookingData.seat_number,
        booking_status: 'confirmed',
        total_amount: bookingData.total_amount,
        booking_date: now,
        created_at: now,
      }
      
      const restOperation = post({
        apiName: API_NAME,
        path: '/bookings',
        options: {
          body: JSON.stringify(booking),
        },
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.booking
    } catch (error) {
      console.error('Error creating booking:', error)
      throw new Error('Failed to create booking')
    }
  }

  async getUserBookings(): Promise<Booking[]> {
    try {
      const user = await getCurrentUser()
      
      const restOperation = get({
        apiName: API_NAME,
        path: `/bookings/user/${user.userId}`,
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.bookings || []
    } catch (error) {
      console.error('Error fetching user bookings:', error)
      throw new Error('Failed to fetch bookings')
    }
  }

  async getBookingById(bookingId: string): Promise<Booking | null> {
    try {
      const restOperation = get({
        apiName: API_NAME,
        path: `/bookings/${bookingId}`,
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.booking || null
    } catch (error) {
      console.error('Error fetching booking:', error)
      throw new Error('Failed to fetch booking details')
    }
  }

  async updateBooking(bookingId: string, updateData: Partial<Booking>): Promise<Booking> {
    try {
      const restOperation = put({
        apiName: API_NAME,
        path: `/bookings/${bookingId}`,
        options: {
          body: JSON.stringify({
            ...updateData,
            updated_at: this.formatDate(),
          }),
        },
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.booking
    } catch (error) {
      console.error('Error updating booking:', error)
      throw new Error('Failed to update booking')
    }
  }

  async cancelBooking(bookingId: string): Promise<void> {
    try {
      await this.updateBooking(bookingId, { booking_status: 'cancelled' })
    } catch (error) {
      console.error('Error cancelling booking:', error)
      throw new Error('Failed to cancel booking')
    }
  }

  async deleteBooking(bookingId: string): Promise<void> {
    try {
      const restOperation = del({
        apiName: API_NAME,
        path: `/bookings/${bookingId}`,
      })

      await restOperation.response
    } catch (error) {
      console.error('Error deleting booking:', error)
      throw new Error('Failed to delete booking')
    }
  }

  // Payment API
  async createPayment(paymentData: {
    booking_id: string
    payment_method: string
    amount: number
    currency?: string
    transaction_id?: string
    payment_gateway?: string
  }): Promise<Payment> {
    try {
      const user = await getCurrentUser()
      const paymentId = uuidv4()
      const now = this.formatDate()
      
      const payment: Payment = {
        id: paymentId,
        booking_id: paymentData.booking_id,
        user_id: user.userId,
        payment_method: paymentData.payment_method,
        payment_status: 'pending',
        amount: paymentData.amount,
        currency: paymentData.currency || 'USD',
        transaction_id: paymentData.transaction_id,
        payment_gateway: paymentData.payment_gateway,
        payment_date: now,
        created_at: now,
      }
      
      const restOperation = post({
        apiName: API_NAME,
        path: '/payments',
        options: {
          body: JSON.stringify(payment),
        },
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.payment
    } catch (error) {
      console.error('Error creating payment:', error)
      throw new Error('Failed to process payment')
    }
  }

  async getPaymentsByBooking(bookingId: string): Promise<Payment[]> {
    try {
      const restOperation = get({
        apiName: API_NAME,
        path: `/payments/booking/${bookingId}`,
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.payments || []
    } catch (error) {
      console.error('Error fetching payments:', error)
      throw new Error('Failed to fetch payments')
    }
  }

  // User Profile API (DynamoDB-based)
  async updateUserProfile(profileData: {
    firstName?: string
    lastName?: string
    email?: string
    preferences?: any
  }): Promise<void> {
    try {
      const user = await getCurrentUser()
      
      const restOperation = put({
        apiName: API_NAME,
        path: `/users/${user.userId}`,
        options: {
          body: JSON.stringify({
            ...profileData,
            updated_at: this.formatDate(),
          }),
        },
      })

      await restOperation.response
    } catch (error) {
      console.error('Error updating user profile:', error)
      throw new Error('Failed to update user profile')
    }
  }

  // Analytics and reporting (bonus features for DynamoDB)
  async getFlightsByAirline(airline: string): Promise<Flight[]> {
    try {
      const restOperation = get({
        apiName: API_NAME,
        path: `/flights/airline/${airline}`,
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.flights || []
    } catch (error) {
      console.error('Error fetching flights by airline:', error)
      throw new Error('Failed to fetch flights by airline')
    }
  }

  async getBookingStats(): Promise<any> {
    try {
      const restOperation = get({
        apiName: API_NAME,
        path: '/analytics/bookings',
      })

      const response = await restOperation.response
      const data = await response.body.json() as any
      return data.stats || {}
    } catch (error) {
      console.error('Error fetching booking stats:', error)
      return {}
    }
  }
}

// Export singleton instance
export const dynamoDBAPIService = new DynamoDBAWSAPIService()
export default dynamoDBAPIService