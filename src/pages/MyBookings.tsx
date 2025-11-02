import { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Plane,
  ArrowLeft,
  Calendar,
  MapPin,
  Users,
  CreditCard,
} from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

interface Booking {
  id: string;
  booking_reference: string;
  flight_number: string;
  departure_airport: string;
  arrival_airport: string;
  departure_time: string;
  arrival_time: string;
  departure_date: string;
  passengers: number;
  seats: string[];
  total_price: number;
  currency: string;
  status: string;
  created_at: string;
}

const MyBookings = () => {
  const { user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [bookings, setBookings] = useState<Booking[]>([]);

  useEffect(() => {
    if (!authLoading && !user) {
      navigate("/auth");
    }
  }, [user, authLoading, navigate]);

  useEffect(() => {
    if (user) {
      fetchBookings();
    }
  }, [user, fetchBookings]);

  const fetchBookings = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from("bookings")
        .select("*")
        .eq("user_id", user?.id)
        .order("created_at", { ascending: false });

      if (error) throw error;

      setBookings(data || []);
    } catch (error) {
      toast.error("Error loading bookings");
    } finally {
      setLoading(false);
    }
  }, [user]);

  if (loading || authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Plane className="w-12 h-12 text-primary animate-pulse mx-auto mb-4" />
          <p className="text-muted-foreground">Loading bookings...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <header className="bg-card shadow-sm sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="icon" onClick={() => navigate("/")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div className="flex items-center gap-2">
              <Plane className="w-6 h-6 text-primary" />
              <h1 className="text-2xl font-bold">My Bookings</h1>
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {bookings.length === 0 ? (
            <Card>
              <CardContent className="pt-8 pb-8">
                <div className="text-center">
                  <Plane className="w-16 h-16 text-muted-foreground mx-auto mb-4 opacity-50" />
                  <h3 className="text-xl font-semibold mb-2">
                    No bookings yet
                  </h3>
                  <p className="text-muted-foreground mb-6">
                    Start your journey by booking your first flight with
                    SkyWings Airlines
                  </p>
                  <Button onClick={() => navigate("/")}>Search Flights</Button>
                </div>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {bookings.map((booking) => (
                <Card
                  key={booking.id}
                  className="hover:shadow-md transition-shadow"
                >
                  <CardHeader>
                    <div className="flex items-start justify-between">
                      <div>
                        <CardTitle className="text-xl mb-1">
                          {booking.departure_airport} →{" "}
                          {booking.arrival_airport}
                        </CardTitle>
                        <p className="text-sm text-muted-foreground">
                          Flight {booking.flight_number}
                        </p>
                      </div>
                      <Badge
                        variant={
                          booking.status === "confirmed"
                            ? "default"
                            : "secondary"
                        }
                      >
                        {booking.status}
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="flex items-start gap-3">
                        <Calendar className="w-5 h-5 text-primary mt-0.5" />
                        <div>
                          <p className="text-sm font-medium">Departure</p>
                          <p className="text-sm text-muted-foreground">
                            {new Date(
                              booking.departure_date,
                            ).toLocaleDateString("en-US", {
                              weekday: "short",
                              year: "numeric",
                              month: "short",
                              day: "numeric",
                            })}
                          </p>
                          <p className="text-sm text-muted-foreground">
                            {booking.departure_time}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-start gap-3">
                        <MapPin className="w-5 h-5 text-primary mt-0.5" />
                        <div>
                          <p className="text-sm font-medium">Arrival</p>
                          <p className="text-sm text-muted-foreground">
                            {booking.arrival_time}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-start gap-3">
                        <Users className="w-5 h-5 text-primary mt-0.5" />
                        <div>
                          <p className="text-sm font-medium">Passengers</p>
                          <p className="text-sm text-muted-foreground">
                            {booking.passengers}{" "}
                            {booking.passengers === 1
                              ? "passenger"
                              : "passengers"}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            Seats: {booking.seats.join(", ")}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-start gap-3">
                        <CreditCard className="w-5 h-5 text-primary mt-0.5" />
                        <div>
                          <p className="text-sm font-medium">Total Paid</p>
                          <p className="text-lg font-bold text-primary">
                            {booking.currency === "USD" && "$"}
                            {booking.currency === "EUR" && "€"}
                            {booking.currency === "GBP" && "£"}
                            {!["USD", "EUR", "GBP"].includes(
                              booking.currency,
                            ) && booking.currency + " "}
                            {booking.total_price}
                          </p>
                        </div>
                      </div>
                    </div>

                    <div className="pt-4 border-t">
                      <div>
                        <p className="text-xs text-muted-foreground">
                          Booking Reference
                        </p>
                        <p className="font-mono font-semibold text-lg">
                          {booking.booking_reference}
                        </p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default MyBookings;
