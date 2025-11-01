import { useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Plane, ArrowLeft, Utensils, Luggage, Wifi, ShieldCheck } from "lucide-react";
import { toast } from "sonner";
import { useCurrency } from "@/contexts/CurrencyContext";

const AddOns = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { currency } = useCurrency();
  
  const flightNumber = searchParams.get("flight") || "SW 1234";
  const returnFlightNumber = searchParams.get("returnFlight");
  const isRoundTrip = !!returnFlightNumber;
  const basePrice = parseInt(searchParams.get("price") || "289");
  const returnPrice = parseInt(searchParams.get("returnPrice") || "0");
  const seatPrice = parseInt(searchParams.get("seatPrice") || "0");
  const returnSeatPrice = parseInt(searchParams.get("returnSeatPrice") || "0");
  const seats = searchParams.get("seats") || "";
  const returnSeats = searchParams.get("returnSeats") || "";

  const [selectedAddOns, setSelectedAddOns] = useState<string[]>([]);

  const addOns = [
    {
      id: "meal",
      name: "In-Flight Meal",
      description: "Choose from a selection of gourmet meals",
      price: 25,
      icon: Utensils,
    },
    {
      id: "baggage",
      name: "Extra Baggage",
      description: "Add 23kg checked baggage",
      price: 45,
      icon: Luggage,
    },
    {
      id: "wifi",
      name: "Wi-Fi Access",
      description: "Stay connected throughout your flight",
      price: 15,
      icon: Wifi,
    },
    {
      id: "insurance",
      name: "Travel Insurance",
      description: "Comprehensive coverage for your trip",
      price: 35,
      icon: ShieldCheck,
    },
  ];

  const toggleAddOn = (id: string) => {
    setSelectedAddOns((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const addOnsTotal = selectedAddOns.reduce((total, id) => {
    const addOn = addOns.find((a) => a.id === id);
    return total + (addOn?.price || 0);
  }, 0);

  const totalPrice = basePrice + returnPrice + seatPrice + returnSeatPrice + addOnsTotal;

  const handleContinue = () => {
    const params = new URLSearchParams(searchParams);
    params.set('addOns', selectedAddOns.join(','));
    params.set('addOnsPrice', addOnsTotal.toString());
    navigate(`/payment?${params.toString()}`);
  };

  return (
    <div className="min-h-screen bg-muted/30">
      <header className="bg-card shadow-sm sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button
                variant="ghost"
                size="icon"
                onClick={() => navigate(-1)}
              >
                <ArrowLeft className="w-5 h-5" />
              </Button>
              <div className="flex items-center gap-2">
                <Plane className="w-6 h-6 text-primary" />
                <h1 className="text-2xl font-bold">Enhance Your Journey</h1>
              </div>
            </div>
            <div className="text-sm text-muted-foreground">
              Flight {flightNumber}
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="grid lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-4">
            {addOns.map((addOn) => {
              const Icon = addOn.icon;
              const isSelected = selectedAddOns.includes(addOn.id);

              return (
                <Card
                  key={addOn.id}
                  className={`cursor-pointer transition-all hover:shadow-md ${
                    isSelected ? "ring-2 ring-primary" : ""
                  }`}
                  onClick={() => toggleAddOn(addOn.id)}
                >
                  <CardContent className="p-6">
                    <div className="flex items-start gap-4">
                      <Checkbox
                        checked={isSelected}
                        onCheckedChange={() => toggleAddOn(addOn.id)}
                        className="mt-1"
                      />
                      <div className="flex-1 flex items-start gap-4">
                        <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center">
                          <Icon className="w-6 h-6 text-primary" />
                        </div>
                        <div className="flex-1">
                          <h3 className="font-semibold text-lg">{addOn.name}</h3>
                          <p className="text-sm text-muted-foreground mt-1">
                            {addOn.description}
                          </p>
                        </div>
                        <div className="text-right">
                          <div className="text-2xl font-bold text-primary">
                            {currency.symbol}{addOn.price}
                          </div>
                          <div className="text-xs text-muted-foreground">
                            per person
                          </div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}

            <Card className="bg-accent/5 border-accent/20">
              <CardContent className="p-6">
                <div className="flex items-start gap-3">
                  <ShieldCheck className="w-5 h-5 text-accent mt-1" />
                  <div>
                    <h4 className="font-semibold">Flexible Booking</h4>
                    <p className="text-sm text-muted-foreground mt-1">
                      Free cancellation within 24 hours of booking. Terms and
                      conditions apply.
                    </p>
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
                <div>
                  <div className="text-sm text-muted-foreground">Flight</div>
                  <div className="font-medium">{flightNumber}</div>
                  {isRoundTrip && (
                    <div className="font-medium text-sm mt-1">{returnFlightNumber}</div>
                  )}
                </div>

                <div>
                  <div className="text-sm text-muted-foreground">
                    Selected Seats
                  </div>
                  <div className="font-medium">
                    <div>Outbound: {seats || "None"}</div>
                    {isRoundTrip && (
                      <div className="text-sm mt-1">Return: {returnSeats || "None"}</div>
                    )}
                  </div>
                </div>

                <div>
                  <div className="text-sm text-muted-foreground mb-2">
                    Add-ons
                  </div>
                  {selectedAddOns.length > 0 ? (
                    <div className="space-y-1">
                      {selectedAddOns.map((id) => {
                        const addOn = addOns.find((a) => a.id === id);
                        return (
                          <div key={id} className="text-sm flex justify-between">
                            <span>{addOn?.name}</span>
                            <span>{currency.symbol}{addOn?.price}</span>
                          </div>
                        );
                      })}
                    </div>
                  ) : (
                    <div className="text-sm text-muted-foreground">None</div>
                  )}
                </div>

                <div className="border-t pt-4 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>Base Fare</span>
                    <span>{currency.symbol}{isRoundTrip ? basePrice + returnPrice : basePrice}</span>
                  </div>
                  {(seatPrice + returnSeatPrice) > 0 && (
                    <div className="flex justify-between text-sm">
                      <span>Seat Selection</span>
                      <span>{currency.symbol}{seatPrice + returnSeatPrice}</span>
                    </div>
                  )}
                  {addOnsTotal > 0 && (
                    <div className="flex justify-between text-sm">
                      <span>Add-ons</span>
                      <span>{currency.symbol}{addOnsTotal}</span>
                    </div>
                  )}
                  <div className="flex justify-between font-bold text-lg pt-2 border-t">
                    <span>Total</span>
                    <span className="text-primary">{currency.symbol}{totalPrice}</span>
                  </div>
                </div>

                <Button className="w-full" size="lg" onClick={handleContinue}>
                  Continue to Payment
                </Button>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AddOns;
