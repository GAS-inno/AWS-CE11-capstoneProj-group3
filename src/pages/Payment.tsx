import { useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Plane, ArrowLeft, CreditCard, Lock } from "lucide-react";
import { toast } from "sonner";
import { useCurrency } from "@/contexts/CurrencyContext";

const Payment = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [isProcessing, setIsProcessing] = useState(false);
  const { currency } = useCurrency();

  const flightNumber = searchParams.get("flight") || "SW 1234";
  const returnFlightNumber = searchParams.get("returnFlight");
  const isRoundTrip = !!returnFlightNumber;
  const basePrice = parseInt(searchParams.get("price") || "289");
  const returnPrice = parseInt(searchParams.get("returnPrice") || "0");
  const seatPrice = parseInt(searchParams.get("seatPrice") || "0");
  const returnSeatPrice = parseInt(searchParams.get("returnSeatPrice") || "0");
  const addOnsPrice = parseInt(searchParams.get("addOnsPrice") || "0");
  const seats = searchParams.get("seats") || "";
  const returnSeats = searchParams.get("returnSeats") || "";
  const addOns = searchParams.get("addOns") || "";

  const totalPrice =
    basePrice + returnPrice + seatPrice + returnSeatPrice + addOnsPrice;

  const [formData, setFormData] = useState({
    cardName: "",
    cardNumber: "",
    expiryDate: "",
    cvv: "",
    email: "",
    phone: "",
  });

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;

    let formattedValue = value;

    if (name === "cardNumber") {
      formattedValue = value
        .replace(/\s/g, "")
        .replace(/(\d{4})/g, "$1 ")
        .trim();
    } else if (name === "expiryDate") {
      formattedValue = value
        .replace(/\D/g, "")
        .replace(/(\d{2})(\d)/, "$1/$2")
        .slice(0, 5);
    } else if (name === "cvv") {
      formattedValue = value.replace(/\D/g, "").slice(0, 3);
    }

    setFormData((prev) => ({ ...prev, [name]: formattedValue }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (
      !formData.cardName ||
      !formData.cardNumber ||
      !formData.expiryDate ||
      !formData.cvv ||
      !formData.email
    ) {
      toast.error("Please fill in all required fields");
      return;
    }

    setIsProcessing(true);

    // Simulate payment processing
    setTimeout(() => {
      setIsProcessing(false);
      toast.success("Payment successful!");
      const params = new URLSearchParams(searchParams);
      params.set("totalPrice", totalPrice.toString());
      navigate(`/confirmation?${params.toString()}`);
    }, 2000);
  };

  return (
    <div className="min-h-screen bg-muted/30">
      <header className="bg-card shadow-sm sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
                <ArrowLeft className="w-5 h-5" />
              </Button>
              <div className="flex items-center gap-2">
                <Plane className="w-6 h-6 text-primary" />
                <h1 className="text-2xl font-bold">Payment</h1>
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
          <div className="lg:col-span-2">
            <form onSubmit={handleSubmit}>
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <CreditCard className="w-5 h-5" />
                    Payment Details
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <Label htmlFor="cardName">Cardholder Name</Label>
                    <Input
                      id="cardName"
                      name="cardName"
                      placeholder="John Doe"
                      value={formData.cardName}
                      onChange={handleInputChange}
                      required
                    />
                  </div>

                  <div>
                    <Label htmlFor="cardNumber">Card Number</Label>
                    <Input
                      id="cardNumber"
                      name="cardNumber"
                      placeholder="1234 5678 9012 3456"
                      value={formData.cardNumber}
                      onChange={handleInputChange}
                      maxLength={19}
                      required
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="expiryDate">Expiry Date</Label>
                      <Input
                        id="expiryDate"
                        name="expiryDate"
                        placeholder="MM/YY"
                        value={formData.expiryDate}
                        onChange={handleInputChange}
                        required
                      />
                    </div>
                    <div>
                      <Label htmlFor="cvv">CVV</Label>
                      <Input
                        id="cvv"
                        name="cvv"
                        placeholder="123"
                        value={formData.cvv}
                        onChange={handleInputChange}
                        type="password"
                        required
                      />
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Contact Information</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <Label htmlFor="email">Email Address</Label>
                    <Input
                      id="email"
                      name="email"
                      type="email"
                      placeholder="john@example.com"
                      value={formData.email}
                      onChange={handleInputChange}
                      required
                    />
                  </div>

                  <div>
                    <Label htmlFor="phone">Phone Number</Label>
                    <Input
                      id="phone"
                      name="phone"
                      type="tel"
                      placeholder="+1 (555) 123-4567"
                      value={formData.phone}
                      onChange={handleInputChange}
                    />
                  </div>
                </CardContent>
              </Card>

              <Card className="mt-6 bg-accent/5 border-accent/20">
                <CardContent className="p-4">
                  <div className="flex items-start gap-3">
                    <Lock className="w-5 h-5 text-accent mt-1" />
                    <div>
                      <h4 className="font-semibold text-sm">Secure Payment</h4>
                      <p className="text-xs text-muted-foreground mt-1">
                        Your payment information is encrypted and secure. We
                        never store your card details.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </form>
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
                    <div className="font-medium text-sm mt-1">
                      {returnFlightNumber}
                    </div>
                  )}
                </div>

                <div>
                  <div className="text-sm text-muted-foreground">
                    Selected Seats
                  </div>
                  <div className="font-medium">
                    <div>Outbound: {seats || "None"}</div>
                    {isRoundTrip && (
                      <div className="text-sm mt-1">
                        Return: {returnSeats || "None"}
                      </div>
                    )}
                  </div>
                </div>

                <div className="border-t pt-4 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>Base Fare</span>
                    <span>
                      {currency.symbol}
                      {isRoundTrip ? basePrice + returnPrice : basePrice}
                    </span>
                  </div>
                  {seatPrice + returnSeatPrice > 0 && (
                    <div className="flex justify-between text-sm">
                      <span>Seat Selection</span>
                      <span>
                        {currency.symbol}
                        {seatPrice + returnSeatPrice}
                      </span>
                    </div>
                  )}
                  {addOnsPrice > 0 && (
                    <div className="flex justify-between text-sm">
                      <span>Add-ons</span>
                      <span>
                        {currency.symbol}
                        {addOnsPrice}
                      </span>
                    </div>
                  )}
                  <div className="flex justify-between font-bold text-lg pt-2 border-t">
                    <span>Total</span>
                    <span className="text-primary">
                      {currency.symbol}
                      {totalPrice}
                    </span>
                  </div>
                </div>

                <Button
                  className="w-full"
                  size="lg"
                  onClick={handleSubmit}
                  disabled={isProcessing}
                >
                  {isProcessing
                    ? "Processing..."
                    : `Pay ${currency.symbol}${totalPrice}`}
                </Button>

                <p className="text-xs text-muted-foreground text-center">
                  By completing this purchase, you agree to our Terms &
                  Conditions
                </p>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Payment;
