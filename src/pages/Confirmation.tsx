import { useEffect, useState, useCallback } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Plane, CheckCircle, Mail, Home } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
// import FlightDetails from "@/components/FlightDetails"; // TODO: Component missing
// import BookingSummary from "@/components/BookingSummary"; // TODO: Component missing
import { useAuth } from "@/contexts/AWSAuthContext";
import { toast } from "sonner";
import { useCurrency } from "@/contexts/CurrencyContext";

// TODO: Re-add type when migrating to DynamoDB
// type BookingInsert = Database['public']['Tables']['bookings']['Insert'];

const Confirmation = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { user } = useAuth();
  const { currency } = useCurrency();
  const [bookingReference, setBookingReference] = useState("");
  const [saving, setSaving] = useState(true);

  const flightNumber = searchParams.get("flight") || "SW 1234";
  const returnFlightNumber = searchParams.get("returnFlight");
  const isRoundTrip = !!returnFlightNumber;
  const totalPrice = searchParams.get("totalPrice") || "289";
  const seats = searchParams.get("seats") || "";
  const returnSeats = searchParams.get("returnSeats") || "";
  const from = searchParams.get("from") || "JFK";
  const to = searchParams.get("to") || "LAX";
  const depTime = searchParams.get("depTime") || "09:00";
  const arrTime = searchParams.get("arrTime") || "12:30";
  const returnDepTime = searchParams.get("returnDepTime") || "";
  const returnArrTime = searchParams.get("returnArrTime") || "";
  const passengers = parseInt(searchParams.get("passengers") || "1");
  const basePrice = searchParams.get("price") || "289";
  const returnPrice = searchParams.get("returnPrice") || "0";
  const seatPrice = searchParams.get("seatPrice") || "0";
  const returnSeatPrice = searchParams.get("returnSeatPrice") || "0";
  const currencyCode = searchParams.get("currency") || "USD";
  const departureDate = searchParams.get("departureDate") || "";
  const outboundDepartureDate = searchParams.get("outboundDepartureDate") || "";
  const returnDepartureDate = searchParams.get("returnDepartureDate") || "";

  const saveBooking = useCallback(async () => {
    try {
      // Save booking if user is logged in
      if (user) {
        const API_URL = 'https://3anzpwlae7.execute-api.us-east-1.amazonaws.com/prod';
        
        // Create booking data
        const bookingData = {
          user_id: user.id,
          flight_id: flightNumber,
          passenger_name: `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.email,
          passenger_email: user.email,
          seat_number: seats,
          total_amount: parseFloat(totalPrice),
          booking_status: 'confirmed',
          flight_details: {
            from,
            to,
            departure_time: depTime,
            arrival_time: arrTime,
            flight_number: flightNumber,
            departure_date: outboundDepartureDate || departureDate,
            passengers,
            currency: currencyCode,
            base_price: parseFloat(basePrice),
            seat_price: parseFloat(seatPrice)
          },
          ...(isRoundTrip && returnFlightNumber && {
            return_flight_id: returnFlightNumber,
            return_seat_number: returnSeats,
            return_flight_details: {
              from: to,  // Return flight: from destination back to origin
              to: from,
              departure_time: returnDepTime,
              arrival_time: returnArrTime,
              flight_number: returnFlightNumber,
              departure_date: returnDepartureDate,
              passengers,
              currency: currencyCode,
              base_price: parseFloat(returnPrice),
              seat_price: parseFloat(returnSeatPrice)
            }
          })
        };

        console.log('Saving booking to DynamoDB:', bookingData);

        const response = await fetch(`${API_URL}/bookings`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(bookingData)
        });

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.error || 'Failed to save booking');
        }

        const result = await response.json();
        console.log('Booking saved successfully:', result);
        
        // Use the booking ID from the response as the reference
        if (result.booking && result.booking.id) {
          setBookingReference(result.booking.id.substring(0, 8).toUpperCase());
        } else {
          // Fallback if response structure is different
          setBookingReference(`SW${Math.random().toString(36).substring(2, 8).toUpperCase()}`);
        }
        
        toast.success('Booking saved to your account!');
      } else {
        // Guest booking - generate random reference
        setBookingReference(`SW${Math.random().toString(36).substring(2, 8).toUpperCase()}`);
      }
    } catch (error) {
      console.error("Error saving booking:", error);
      toast.error("Booking confirmed but could not be saved to your account");
      setBookingReference(
        `SW${Math.random().toString(36).substring(2, 8).toUpperCase()}`,
      );
    } finally {
      setSaving(false);
    }
  }, [user, flightNumber, from, to, depTime, arrTime, passengers, seats, basePrice, seatPrice, totalPrice, currencyCode, isRoundTrip, returnFlightNumber, returnDepTime, returnArrTime, returnSeats, returnPrice, returnSeatPrice, departureDate, outboundDepartureDate, returnDepartureDate]);

  useEffect(() => {
    saveBooking();
  }, [saveBooking]);

  if (saving) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Plane className="w-12 h-12 text-primary animate-pulse mx-auto mb-4" />
          <p className="text-muted-foreground">Confirming your booking...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <header className="bg-card shadow-sm">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-2">
            <Plane className="w-6 h-6 text-primary" />
            <h1 className="text-2xl font-bold">SkyWings Airlines</h1>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-12">
        <div className="max-w-2xl mx-auto">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-green-100 mb-4">
              <CheckCircle className="w-10 h-10 text-green-600" />
            </div>
            <h1 className="text-3xl font-bold mb-2">Booking Confirmed!</h1>
            <p className="text-muted-foreground">
              Your flight has been successfully booked
            </p>
          </div>

          <Card className="mb-6">
            <CardHeader>
              <CardTitle>Booking Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <div className="text-sm text-muted-foreground">
                    Booking Reference
                  </div>
                  <div className="font-bold text-lg">{bookingReference}</div>
                </div>
                <div>
                  <div className="text-sm text-muted-foreground">
                    Flight Number{isRoundTrip ? "s" : ""}
                  </div>
                  <div className="font-medium">
                    {flightNumber}
                    {isRoundTrip && `, ${returnFlightNumber}`}
                  </div>
                </div>
              </div>

              <div className="border-t pt-4">
                <div className="text-sm text-muted-foreground mb-2">
                  Travel Dates
                </div>
                <div className="font-medium space-y-1">
                  <div>
                    Outbound:{" "}
                    {outboundDepartureDate || departureDate
                      ? new Date(
                          outboundDepartureDate || departureDate,
                        ).toLocaleDateString("en-US", {
                          weekday: "short",
                          year: "numeric",
                          month: "short",
                          day: "numeric",
                        })
                      : "Date not available"}
                    <span className="text-muted-foreground text-sm ml-2">
                      {from} → {to} at {depTime}
                    </span>
                  </div>
                  {isRoundTrip && returnDepartureDate && (
                    <div className="text-sm">
                      Return:{" "}
                      {new Date(returnDepartureDate).toLocaleDateString(
                        "en-US",
                        {
                          weekday: "short",
                          year: "numeric",
                          month: "short",
                          day: "numeric",
                        },
                      )}
                      <span className="text-muted-foreground ml-2">
                        {to} → {from} at {returnDepTime}
                      </span>
                    </div>
                  )}
                </div>
              </div>

              <div className="border-t pt-4">
                <div className="text-sm text-muted-foreground mb-2">
                  Selected Seats
                </div>
                <div className="font-medium">
                  <div>Outbound: {seats || "Standard seating"}</div>
                  {isRoundTrip && (
                    <div className="text-sm mt-1">
                      Return: {returnSeats || "Standard seating"}
                    </div>
                  )}
                </div>
              </div>

              <div className="border-t pt-4">
                <div className="flex justify-between items-center">
                  <span className="text-lg font-semibold">Total Paid</span>
                  <span className="text-2xl font-bold text-primary">
                    {currency.symbol}
                    {totalPrice}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="mb-6">
            <CardContent className="p-6">
              <div className="flex items-start gap-4">
                <Mail className="w-5 h-5 text-primary mt-1" />
                <div>
                  <h3 className="font-semibold mb-1">
                    Confirmation Email Sent
                  </h3>
                  <p className="text-sm text-muted-foreground">
                    We've sent your booking confirmation and e-ticket to your
                    email address. Please check your inbox.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <div className="flex justify-center">
            <Button
              size="lg"
              className="w-full sm:w-auto"
              onClick={() => navigate("/")}
            >
              <Home className="w-4 h-4 mr-2" />
              Back to Home
            </Button>
          </div>

          <Card className="mt-6 bg-accent/5 border-accent/20">
            <CardContent className="p-4">
              <h4 className="font-semibold text-sm mb-2">
                Important Information
              </h4>
              <ul className="text-xs text-muted-foreground space-y-1">
                <li>• Check-in opens 24 hours before departure</li>
                <li>
                  • Arrive at the airport at least 2 hours before departure
                </li>
                <li>• Bring a valid ID and your booking reference</li>
                <li>• Review baggage allowances and restrictions</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default Confirmation;
