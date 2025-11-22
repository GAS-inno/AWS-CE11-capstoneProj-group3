import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Plane, Clock } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useCurrency } from "@/contexts/CurrencyContext";

interface FlightCardProps {
  airline: string;
  flightNumber: string;
  departure: {
    time: string;
    airport: string;
  };
  arrival: {
    time: string;
    airport: string;
  };
  duration: string;
  price: number;
  stops: number;
  passengers?: string;
  departureDate?: string;
  onSelectOverride?: () => void;
  outboundFlight?: {
    airline: string;
    flightNumber: string;
    departure: { time: string; airport: string };
    arrival: { time: string; airport: string };
    duration: string;
    price: number;
    stops: number;
  };
  outboundDepartureDate?: string;
}

export const FlightCard = ({
  airline,
  flightNumber,
  departure,
  arrival,
  duration,
  price,
  stops,
  passengers = "1",
  departureDate,
  onSelectOverride,
  outboundFlight,
  outboundDepartureDate,
}: FlightCardProps) => {
  const navigate = useNavigate();
  const { currency, convertPrice } = useCurrency();

  const displayPrice = convertPrice(price);
  const outboundDisplayPrice = outboundFlight
    ? convertPrice(outboundFlight.price)
    : 0;
  const totalPrice = outboundFlight
    ? displayPrice + outboundDisplayPrice
    : displayPrice;

  const handleSelectFlight = () => {
    if (onSelectOverride) {
      onSelectOverride();
      // Scroll to return flights section
      setTimeout(() => {
        const returnSection = document.getElementById("return-flights");
        if (returnSection) {
          returnSection.scrollIntoView({ behavior: "smooth", block: "start" });
        }
      }, 100);
      return;
    }

    interface FlightData {
      flight: string;
      price: number;
      currency: string;
      passengers?: string;
      from: string;
      to: string;
      depTime: string;
      arrTime: string;
      duration: string;
      returnFlight?: string;
      returnPrice?: number;
      returnFrom?: string;
      returnTo?: string;
      returnDepTime?: string;
      returnArrTime?: string;
      returnDuration?: string;
      totalPrice?: number;
      returnDepartureDate?: string;
      outboundDepartureDate?: string;
      departureDate?: string;
    }

    const flightData: FlightData = {
      flight: flightNumber,
      price: displayPrice,
      currency: currency.code,
      passengers: passengers,
      from: departure.airport,
      to: arrival.airport,
      depTime: departure.time,
      arrTime: arrival.time,
      duration: duration,
    };

    if (outboundFlight) {
      // Round-trip: setting return flight details
      flightData.returnFlight = flightNumber;  // Current flight is the return
      flightData.returnPrice = displayPrice;
      flightData.returnFrom = departure.airport;  // Current flight's departure
      flightData.returnTo = arrival.airport;      // Current flight's arrival
      flightData.returnDepTime = departure.time;  // Current flight's departure time
      flightData.returnArrTime = arrival.time;    // Current flight's arrival time
      flightData.returnDuration = duration;
      flightData.totalPrice = totalPrice;
      flightData.returnDepartureDate = departureDate ||
        new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)
          .toISOString()
          .split("T")[0]; // Default to 14 days from now
      // Outbound flight details from the previously selected flight
      flightData.flight = outboundFlight.flightNumber;
      flightData.price = outboundDisplayPrice;
      flightData.from = outboundFlight.departure.airport;
      flightData.to = outboundFlight.arrival.airport;
      flightData.depTime = outboundFlight.departure.time;
      flightData.arrTime = outboundFlight.arrival.time;
      flightData.outboundDepartureDate = outboundDepartureDate;
    } else {
      // One-way: use departureDate
      flightData.departureDate =
        departureDate ||
        new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
          .toISOString()
          .split("T")[0]; // Default to 7 days from now
    }

    const params = new URLSearchParams(
      Object.entries(flightData).reduce<Record<string, string>>((acc, [key, value]) => {
        if (value !== undefined) {
          acc[key] = String(value);
        }
        return acc;
      }, {})
    ).toString();
    navigate(`/seat-selection?${params}`);
  };

  return (
    <Card className="hover:shadow-md transition-shadow">
      <CardContent className="p-6">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex-1 space-y-4">
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Plane className="w-4 h-4" />
              <span className="font-medium">{flightNumber}</span>
            </div>

            <div className="flex items-center gap-8">
              <div className="text-center">
                <div className="text-2xl font-bold">{departure.time}</div>
                <div className="text-sm text-muted-foreground">
                  {departure.airport}
                </div>
              </div>

              <div className="flex-1 flex flex-col items-center">
                <div className="w-full h-px bg-border relative">
                  <Plane className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-5 h-5 text-primary rotate-90" />
                </div>
                <div className="flex items-center gap-2 mt-2 text-xs text-muted-foreground">
                  <Clock className="w-3 h-3" />
                  <span>{duration}</span>
                  <span>•</span>
                  <span>
                    {stops === 0
                      ? "Non-stop"
                      : `${stops} stop${stops > 1 ? "s" : ""}`}
                  </span>
                </div>
              </div>

              <div className="text-center">
                <div className="text-2xl font-bold">{arrival.time}</div>
                <div className="text-sm text-muted-foreground">
                  {arrival.airport}
                </div>
              </div>
            </div>
          </div>

          <div className="flex flex-col items-end gap-2 md:border-l md:pl-6">
            {outboundFlight ? (
              <>
                <div className="text-sm text-muted-foreground">
                  Outbound: {currency.symbol}
                  {outboundDisplayPrice}
                </div>
                <div className="text-sm text-muted-foreground">
                  Return: {currency.symbol}
                  {displayPrice}
                </div>
                <div className="text-3xl font-bold text-primary">
                  {currency.symbol}
                  {totalPrice}
                </div>
                <div className="text-sm text-muted-foreground">
                  total per person
                </div>
              </>
            ) : (
              <>
                <div className="text-3xl font-bold text-primary">
                  {currency.symbol}
                  {displayPrice}
                </div>
                <div className="text-sm text-muted-foreground">per person</div>
              </>
            )}
            <Button
              variant="accent"
              className="mt-2"
              onClick={handleSelectFlight}
            >
              {onSelectOverride ? "Select Outbound" : "Select Flight"}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
