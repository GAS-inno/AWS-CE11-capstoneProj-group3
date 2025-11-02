import { get, post, put, del } from '@aws-amplify/api'
import { getCurrentUser } from '@aws-amplify/auth'

// API endpoint constants
const API_NAME = 'BookingAPI'

// DynamoDB table names (will be set via environment variables)
const FLIGHTS_TABLE = import.meta.env.VITE_FLIGHTS_TABLE || 'sky-high-booker-flights'
const BOOKINGS_TABLE = import.meta.env.VITE_BOOKINGS_TABLE || 'sky-high-booker-bookings'
const PAYMENTS_TABLE = import.meta.env.VITE_PAYMENTS_TABLE || 'sky-high-booker-payments'

// Interfaces for our booking system
export interface Flight {
  id: string
  from: string
  to: string
  departure_time: string
  arrival_time: string
  price: number
  airline: string
  flight_number: string
  duration: string
  aircraft: string
  available_seats: number
  created_at?: string
  updated_at?: string
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
  booking_date: string
  created_at?: string
  updated_at?: string
  flight?: Flight
}

export interface CreateBookingData {
  flight_id: string
  passenger_name: string
  passenger_email: string
  seat_number: string
  total_amount: number
}

class AWSAPIService {
  // Helper method to get authorization headers
  private async getAuthHeaders(): Promise<Record<string, string>> {
    try {
      const user = await getCurrentUser()
      // Assuming we store JWT token in user attributes or session
      return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${user.signInDetails?.loginId || ''}`,
      }
    } catch (error) {
      return {
        'Content-Type': 'application/json',
      }
    }
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
      if (params.from) queryParams.append('from', params.from)
      if (params.to) queryParams.append('to', params.to)
      if (params.departure_date) queryParams.append('departure_date', params.departure_date)
      if (params.passengers) queryParams.append('passengers', params.passengers.toString())

      const restOperation = get({
        apiName: API_NAME,
        path: `/flights?${queryParams.toString()}`,
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
      
      const restOperation = post({
        apiName: API_NAME,
        path: '/bookings',
        options: {
          body: {
            ...bookingData,
            user_id: user.userId,
            booking_status: 'confirmed',
            booking_date: new Date().toISOString(),
          },
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
          body: {
            ...updateData,
            updated_at: new Date().toISOString(),
          },
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

  // User Profile API
  async updateUserProfile(profileData: {
    firstName?: string
    lastName?: string
    email?: string
  }): Promise<void> {
    try {
      const user = await getCurrentUser()
      
      const restOperation = put({
        apiName: API_NAME,
        path: `/users/${user.userId}`,
        options: {
          body: profileData,
        },
      })

      await restOperation.response
    } catch (error) {
      console.error('Error updating user profile:', error)
      throw new Error('Failed to update user profile')
    }
  }
}

// Export singleton instance
export const awsAPIService = new AWSAPIService()
export default awsAPIService