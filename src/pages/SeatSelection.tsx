import { useState, useEffect, useCallback } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Plane, ArrowLeft } from "lucide-react";
import { toast } from "sonner";
import { useCurrency } from "@/contexts/CurrencyContext";

const ROWS = 30;
const SEATS_PER_ROW = 6;
const AISLE_AFTER = 3;

const SeatSelection = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [outboundSeats, setOutboundSeats] = useState<string[]>([]);
  const [returnSeats, setReturnSeats] = useState<string[]>([]);
  const [selectingLeg, setSelectingLeg] = useState<"outbound" | "return">(
    "outbound",
  );
  const [occupiedSeats, setOccupiedSeats] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const { currency } = useCurrency();

  const flightNumber = searchParams.get("flight") || "SW 1234";
  const returnFlightNumber = searchParams.get("returnFlight");
  const isRoundTrip = !!returnFlightNumber;
  const price = searchParams.get("price") || "289";
  const returnPrice = searchParams.get("returnPrice") || "0";
  const maxPassengers = parseInt(searchParams.get("passengers") || "1");
  const outboundDepartureDate =
    searchParams.get("outboundDepartureDate") ||
    searchParams.get("departureDate") ||
    "";
  const returnDepartureDate = searchParams.get("returnDepartureDate") || "";

  const currentFlight =
    selectingLeg === "outbound" ? flightNumber : returnFlightNumber;
  const currentDate =
    selectingLeg === "outbound" ? outboundDepartureDate : returnDepartureDate;
  const selectedSeats =
    selectingLeg === "outbound" ? outboundSeats : returnSeats;
  const setSelectedSeats =
    selectingLeg === "outbound" ? setOutboundSeats : setReturnSeats;

  const fetchOccupiedSeats = useCallback(async () => {
    if (!currentFlight || !currentDate) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const API_URL = 'https://3anzpwlae7.execute-api.us-east-1.amazonaws.com/prod';
      
      const response = await fetch(
        `${API_URL}/bookings/occupied-seats?flight_id=${encodeURIComponent(currentFlight)}&departure_date=${encodeURIComponent(currentDate)}`
      );

      if (!response.ok) {
        throw new Error('Failed to fetch occupied seats');
      }

      const data = await response.json();
      console.log('Occupied seats:', data);
      setOccupiedSeats(data.occupied_seats || []);
    } catch (error) {
      console.error("Error fetching occupied seats:", error);
      toast.error("Could not load seat availability");
      setOccupiedSeats([]); // Allow booking to continue even if API fails
    } finally {
      setLoading(false);
    }
  }, [currentFlight, currentDate]);

  // Fetch occupied seats for the current flight and date
  useEffect(() => {
    fetchOccupiedSeats();
  }, [fetchOccupiedSeats, selectingLeg]);

  const getSeatLabel = (rowIndex: number, seatIndex: number): string => {
    const row = rowIndex + 1;
    const seatLetter = String.fromCharCode(65 + seatIndex);
    return `${row}${seatLetter}`;
  };

  const isSeatOccupied = (seatLabel: string) =>
    occupiedSeats.includes(seatLabel);
  const isSeatSelected = (seatLabel: string) =>
    selectedSeats.includes(seatLabel);

  const handleSeatClick = (seatLabel: string) => {
    if (isSeatOccupied(seatLabel)) return;

    if (isSeatSelected(seatLabel)) {
      setSelectedSeats(selectedSeats.filter((s) => s !== seatLabel));
    } else {
      if (selectedSeats.length >= maxPassengers) {
        // For single passenger, replace the seat instead of showing error
        if (maxPassengers === 1) {
          setSelectedSeats([seatLabel]);
        } else {
          toast.error(
            `You can only select ${maxPassengers} seats for ${maxPassengers} passengers`,
          );
        }
        return;
      }
      setSelectedSeats([...selectedSeats, seatLabel]);
    }
  };

  const getSeatPrice = (rowIndex: number) => {
    if (rowIndex < 5) return 50; // Premium
    if (rowIndex < 10) return 30; // Extra legroom
    return 0; // Standard (free)
  };

  const totalSeatPrice = selectedSeats.reduce((total, seat) => {
    const rowIndex = parseInt(seat.slice(0, -1)) - 1;
    return total + getSeatPrice(rowIndex);
  }, 0);

  const handleContinue = () => {
    if (selectedSeats.length === 0) {
      toast.error("Please select at least one seat");
      return;
    }
    if (selectedSeats.length !== maxPassengers) {
      toast.error(
        `Please select exactly ${maxPassengers} seat${maxPassengers > 1 ? "s" : ""} for ${maxPassengers} passenger${maxPassengers > 1 ? "s" : ""}`,
      );
      return;
    }

    // If round trip and still on outbound, switch to return
    if (isRoundTrip && selectingLeg === "outbound") {
      setSelectingLeg("return");
      setLoading(true); // Will trigger useEffect to fetch return flight seats
      toast.success("Outbound seats selected! Now select return seats.");
      window.scrollTo({ top: 0, behavior: "smooth" });
      return;
    }

    // Calculate total seat prices
    const outboundSeatPrice = outboundSeats.reduce((total, seat) => {
      const rowIndex = parseInt(seat.slice(0, -1)) - 1;
      return total + getSeatPrice(rowIndex);
    }, 0);

    const returnSeatPrice = isRoundTrip
      ? returnSeats.reduce((total, seat) => {
          const rowIndex = parseInt(seat.slice(0, -1)) - 1;
          return total + getSeatPrice(rowIndex);
        }, 0)
      : 0;

    const params = new URLSearchParams(searchParams);
    params.set("seats", outboundSeats.join(","));
    params.set("seatPrice", outboundSeatPrice.toString());
    if (isRoundTrip) {
      params.set("returnSeats", returnSeats.join(","));
      params.set("returnSeatPrice", returnSeatPrice.toString());
    }
    navigate(`/add-ons?${params.toString()}`);
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Plane className="w-12 h-12 text-primary animate-pulse mx-auto mb-4" />
          <p className="text-muted-foreground">Loading seat availability...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <header className="bg-card shadow-sm sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button
                variant="ghost"
                size="icon"
                onClick={() => {
                  if (isRoundTrip && selectingLeg === "return") {
                    setSelectingLeg("outbound");
                  } else {
                    navigate("/");
                  }
                }}
              >
                <ArrowLeft className="w-5 h-5" />
              </Button>
              <div className="flex items-center gap-2">
                <Plane className="w-6 h-6 text-primary" />
                <div>
                  <h1 className="text-2xl font-bold">Select Your Seats</h1>
                  {isRoundTrip && (
                    <p className="text-sm text-muted-foreground">
                      {selectingLeg === "outbound"
                        ? "Outbound Flight"
                        : "Return Flight"}{" "}
                      - Step {selectingLeg === "outbound" ? "1" : "2"} of 2
                    </p>
                  )}
                </div>
              </div>
            </div>
            <div className="text-sm text-muted-foreground">
              Flight {currentFlight}
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="grid lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <Card>
              <CardHeader>
                <CardTitle>
                  {isRoundTrip && selectingLeg === "return"
                    ? "Choose Return Seats"
                    : "Choose Your Seats"}
                </CardTitle>
                <p className="text-sm text-muted-foreground mt-2">
                  {isRoundTrip && (
                    <span className="font-medium text-primary">
                      {selectingLeg === "outbound" ? "Outbound: " : "Return: "}
                    </span>
                  )}
                  Select {maxPassengers} seat{maxPassengers > 1 ? "s" : ""} for{" "}
                  {maxPassengers} passenger{maxPassengers > 1 ? "s" : ""}
                </p>
                <div className="flex gap-6 mt-4 text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 bg-muted rounded border" />
                    <span>Available</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 bg-primary rounded" />
                    <span>Selected</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 bg-muted-foreground/20 rounded" />
                    <span>Occupied</span>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="max-w-md mx-auto">
                  {/* Cockpit */}
                  <div className="flex justify-center mb-4">
                    <div className="w-24 h-8 bg-muted rounded-t-full flex items-center justify-center text-xs">
                      Cockpit
                    </div>
                  </div>

                  {/* Seats */}
                  <div className="space-y-2">
                    {Array.from({ length: ROWS }).map((_, rowIndex) => (
                      <div key={rowIndex} className="flex items-center gap-2">
                        <div className="w-8 text-xs text-muted-foreground text-right">
                          {rowIndex + 1}
                        </div>
                        <div className="flex gap-2 flex-1 justify-center">
                          {Array.from({ length: SEATS_PER_ROW }).map(
                            (_, seatIndex) => {
                              const seatLabel = getSeatLabel(
                                rowIndex,
                                seatIndex,
                              );
                              const occupied = isSeatOccupied(seatLabel);
                              const selected = isSeatSelected(seatLabel);
                              const seatPrice = getSeatPrice(rowIndex);

                              return (
                                <div key={seatIndex} className="flex gap-2">
                                  <button
                                    onClick={() => handleSeatClick(seatLabel)}
                                    disabled={occupied}
                                    className={`w-8 h-8 rounded text-xs font-medium transition-all ${
                                      occupied
                                        ? "bg-muted-foreground/20 cursor-not-allowed"
                                        : selected
                                          ? "bg-primary text-primary-foreground"
                                          : "bg-muted border hover:border-primary hover:scale-110"
                                    } ${seatPrice > 0 ? "ring-1 ring-accent/30" : ""}`}
                                    title={`${seatLabel}${seatPrice > 0 ? ` (+${currency.symbol}${seatPrice})` : ""}`}
                                  >
                                    {seatLabel.slice(-1)}
                                  </button>
                                  {seatIndex === AISLE_AFTER - 1 && (
                                    <div className="w-4" />
                                  )}
                                </div>
                              );
                            },
                          )}
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* Legend for pricing */}
                  <div className="mt-6 space-y-2 text-sm">
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 rounded ring-1 ring-accent/30 bg-muted" />
                      <span>Rows 1-5: Premium (+{currency.symbol}50)</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 rounded ring-1 ring-accent/30 bg-muted" />
                      <span>
                        Rows 6-10: Extra Legroom (+{currency.symbol}30)
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 rounded bg-muted" />
                      <span>Rows 11+: Standard (Free)</span>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="lg:col-span-1">
            <Card className="sticky top-24">
              <CardHeader>
                <CardTitle>Booking Summary</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {isRoundTrip ? (
                  <>
                    <div
                      className={
                        selectingLeg === "outbound" ? "" : "opacity-50"
                      }
                    >
                      <div className="text-sm text-muted-foreground">
                        Outbound Flight
                      </div>
                      <div className="font-medium text-sm">{flightNumber}</div>
                      <div className="text-xs text-muted-foreground mt-1">
                        Seats:{" "}
                        {outboundSeats.length > 0
                          ? outboundSeats.join(", ")
                          : "Not selected"}
                      </div>
                    </div>

                    <div
                      className={selectingLeg === "return" ? "" : "opacity-50"}
                    >
                      <div className="text-sm text-muted-foreground">
                        Return Flight
                      </div>
                      <div className="font-medium text-sm">
                        {returnFlightNumber}
                      </div>
                      <div className="text-xs text-muted-foreground mt-1">
                        Seats:{" "}
                        {returnSeats.length > 0
                          ? returnSeats.join(", ")
                          : "Not selected"}
                      </div>
                    </div>

                    <div className="border-t pt-4">
                      <div className="text-sm font-medium mb-2">
                        {selectingLeg === "outbound" ? "Outbound" : "Return"} -
                        Selected Seats ({selectedSeats.length}/{maxPassengers})
                      </div>
                      <div className="font-medium text-sm">
                        {selectedSeats.length > 0
                          ? selectedSeats.join(", ")
                          : "None"}
                      </div>
                    </div>
                  </>
                ) : (
                  <>
                    <div>
                      <div className="text-sm text-muted-foreground">
                        Flight
                      </div>
                      <div className="font-medium">{flightNumber}</div>
                    </div>

                    <div>
                      <div className="text-sm text-muted-foreground">
                        Selected Seats ({selectedSeats.length}/{maxPassengers})
                      </div>
                      <div className="font-medium">
                        {selectedSeats.length > 0
                          ? selectedSeats.join(", ")
                          : "None"}
                      </div>
                    </div>
                  </>
                )}

                <div className="border-t pt-4 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>Base Fare</span>
                    <span>
                      {currency.symbol}
                      {isRoundTrip
                        ? parseInt(price) + parseInt(returnPrice)
                        : price}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span>Seat Selection</span>
                    <span>
                      {currency.symbol}
                      {totalSeatPrice}
                    </span>
                  </div>
                  <div className="flex justify-between font-bold text-lg pt-2 border-t">
                    <span>Total</span>
                    <span className="text-primary">
                      {currency.symbol}
                      {(isRoundTrip
                        ? parseInt(price) + parseInt(returnPrice)
                        : parseInt(price)) + totalSeatPrice}
                    </span>
                  </div>
                </div>

                <Button className="w-full" size="lg" onClick={handleContinue}>
                  {isRoundTrip && selectingLeg === "outbound"
                    ? "Continue to Return Seats"
                    : "Continue to Add-ons"}
                </Button>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SeatSelection;
