import { useState } from "react";
import { FlightSearchForm } from "@/components/FlightSearchForm";
import { FlightCard } from "@/components/FlightCard";
import { CurrencySelector } from "@/components/CurrencySelector";
import { UserMenu } from "@/components/UserMenu";
import heroImage from "@/assets/hero-flight.jpg";
import { Plane } from "lucide-react";

const mockFlights = [
  // JFK to LAX
  {
    airline: "SkyWings",
    flightNumber: "SW 1234",
    departure: { time: "09:00", airport: "JFK" },
    arrival: { time: "12:30", airport: "LAX" },
    duration: "5h 30m",
    price: 289,
    stops: 0,
  },
  {
    airline: "AirConnect",
    flightNumber: "AC 5678",
    departure: { time: "14:15", airport: "JFK" },
    arrival: { time: "18:05", airport: "LAX" },
    duration: "5h 50m",
    price: 245,
    stops: 1,
  },
  {
    airline: "GlobalAir",
    flightNumber: "GA 9012",
    departure: { time: "18:30", airport: "JFK" },
    arrival: { time: "22:15", airport: "LAX" },
    duration: "5h 45m",
    price: 312,
    stops: 0,
  },
  // LAX to JFK
  {
    airline: "SkyWings",
    flightNumber: "SW 2341",
    departure: { time: "08:00", airport: "LAX" },
    arrival: { time: "16:30", airport: "JFK" },
    duration: "5h 30m",
    price: 295,
    stops: 0,
  },
  {
    airline: "GlobalAir",
    flightNumber: "GA 3456",
    departure: { time: "13:45", airport: "LAX" },
    arrival: { time: "22:15", airport: "JFK" },
    duration: "5h 30m",
    price: 275,
    stops: 0,
  },
  // JFK to LHR
  {
    airline: "GlobalAir",
    flightNumber: "GA 7001",
    departure: { time: "20:00", airport: "JFK" },
    arrival: { time: "08:15", airport: "LHR" },
    duration: "7h 15m",
    price: 485,
    stops: 0,
  },
  {
    airline: "SkyWings",
    flightNumber: "SW 7002",
    departure: { time: "22:30", airport: "JFK" },
    arrival: { time: "10:45", airport: "LHR" },
    duration: "7h 15m",
    price: 520,
    stops: 0,
  },
  // LHR to JFK
  {
    airline: "AirConnect",
    flightNumber: "AC 8001",
    departure: { time: "10:00", airport: "LHR" },
    arrival: { time: "13:00", airport: "JFK" },
    duration: "8h 0m",
    price: 495,
    stops: 0,
  },
  // SIN to BKK
  {
    airline: "AirConnect",
    flightNumber: "AC 3001",
    departure: { time: "09:30", airport: "SIN" },
    arrival: { time: "11:00", airport: "BKK" },
    duration: "2h 30m",
    price: 145,
    stops: 0,
  },
  {
    airline: "SkyWings",
    flightNumber: "SW 3002",
    departure: { time: "15:15", airport: "SIN" },
    arrival: { time: "16:45", airport: "BKK" },
    duration: "2h 30m",
    price: 155,
    stops: 0,
  },
  // BKK to SIN
  {
    airline: "GlobalAir",
    flightNumber: "GA 4001",
    departure: { time: "12:00", airport: "BKK" },
    arrival: { time: "15:30", airport: "SIN" },
    duration: "2h 30m",
    price: 150,
    stops: 0,
  },
  // SIN to HKG
  {
    airline: "SkyWings",
    flightNumber: "SW 5001",
    departure: { time: "08:00", airport: "SIN" },
    arrival: { time: "12:00", airport: "HKG" },
    duration: "4h 0m",
    price: 235,
    stops: 0,
  },
  // HKG to NRT
  {
    airline: "AirConnect",
    flightNumber: "AC 6001",
    departure: { time: "10:30", airport: "HKG" },
    arrival: { time: "15:30", airport: "NRT" },
    duration: "5h 0m",
    price: 325,
    stops: 0,
  },
  // DXB to LHR
  {
    airline: "GlobalAir",
    flightNumber: "GA 9001",
    departure: { time: "03:00", airport: "DXB" },
    arrival: { time: "07:30", airport: "LHR" },
    duration: "7h 30m",
    price: 445,
    stops: 0,
  },
  // LHR to DXB
  {
    airline: "SkyWings",
    flightNumber: "SW 9002",
    departure: { time: "14:00", airport: "LHR" },
    arrival: { time: "23:30", airport: "DXB" },
    duration: "7h 30m",
    price: 455,
    stops: 0,
  },
  // DXB to JFK
  {
    airline: "GlobalAir",
    flightNumber: "GA 9100",
    departure: { time: "02:00", airport: "DXB" },
    arrival: { time: "08:30", airport: "JFK" },
    duration: "14h 30m",
    price: 685,
    stops: 0,
  },
  {
    airline: "AirConnect",
    flightNumber: "AC 9101",
    departure: { time: "10:00", airport: "DXB" },
    arrival: { time: "16:30", airport: "JFK" },
    duration: "14h 30m",
    price: 725,
    stops: 0,
  },
  // JFK to DXB
  {
    airline: "SkyWings",
    flightNumber: "SW 9200",
    departure: { time: "22:00", airport: "JFK" },
    arrival: { time: "18:30", airport: "DXB" },
    duration: "12h 30m",
    price: 695,
    stops: 0,
  },
  {
    airline: "GlobalAir",
    flightNumber: "GA 9201",
    departure: { time: "23:30", airport: "JFK" },
    arrival: { time: "20:00", airport: "DXB" },
    duration: "12h 30m",
    price: 715,
    stops: 0,
  },
  // SIN to SYD
  {
    airline: "SkyWings",
    flightNumber: "SW 8001",
    departure: { time: "08:00", airport: "SIN" },
    arrival: { time: "18:30", airport: "SYD" },
    duration: "8h 30m",
    price: 485,
    stops: 0,
  },
  {
    airline: "AirConnect",
    flightNumber: "AC 8002",
    departure: { time: "14:00", airport: "SIN" },
    arrival: { time: "00:30", airport: "SYD" },
    duration: "8h 30m",
    price: 465,
    stops: 0,
  },
  // SYD to SIN
  {
    airline: "GlobalAir",
    flightNumber: "GA 8100",
    departure: { time: "10:00", airport: "SYD" },
    arrival: { time: "16:00", airport: "SIN" },
    duration: "8h 0m",
    price: 475,
    stops: 0,
  },
  {
    airline: "SkyWings",
    flightNumber: "SW 8101",
    departure: { time: "22:00", airport: "SYD" },
    arrival: { time: "04:00", airport: "SIN" },
    duration: "8h 0m",
    price: 455,
    stops: 0,
  },
  // LHR to SIN
  {
    airline: "GlobalAir",
    flightNumber: "GA 7100",
    departure: { time: "11:00", airport: "LHR" },
    arrival: { time: "07:30", airport: "SIN" },
    duration: "13h 30m",
    price: 625,
    stops: 0,
  },
  {
    airline: "AirConnect",
    flightNumber: "AC 7101",
    departure: { time: "21:00", airport: "LHR" },
    arrival: { time: "17:30", airport: "SIN" },
    duration: "13h 30m",
    price: 645,
    stops: 0,
  },
  // SIN to LHR
  {
    airline: "SkyWings",
    flightNumber: "SW 7200",
    departure: { time: "23:00", airport: "SIN" },
    arrival: { time: "05:30", airport: "LHR" },
    duration: "14h 30m",
    price: 635,
    stops: 0,
  },
  // CDG to JFK
  {
    airline: "GlobalAir",
    flightNumber: "GA 6001",
    departure: { time: "10:00", airport: "CDG" },
    arrival: { time: "12:30", airport: "JFK" },
    duration: "8h 30m",
    price: 515,
    stops: 0,
  },
  {
    airline: "SkyWings",
    flightNumber: "SW 6002",
    departure: { time: "18:00", airport: "CDG" },
    arrival: { time: "20:30", airport: "JFK" },
    duration: "8h 30m",
    price: 535,
    stops: 0,
  },
  // JFK to CDG
  {
    airline: "AirConnect",
    flightNumber: "AC 6100",
    departure: { time: "20:00", airport: "JFK" },
    arrival: { time: "09:30", airport: "CDG" },
    duration: "7h 30m",
    price: 525,
    stops: 0,
  },
  {
    airline: "GlobalAir",
    flightNumber: "GA 6101",
    departure: { time: "22:30", airport: "JFK" },
    arrival: { time: "12:00", airport: "CDG" },
    duration: "7h 30m",
    price: 545,
    stops: 0,
  },
  // NRT to LAX
  {
    airline: "SkyWings",
    flightNumber: "SW 5100",
    departure: { time: "18:00", airport: "NRT" },
    arrival: { time: "11:00", airport: "LAX" },
    duration: "10h 0m",
    price: 565,
    stops: 0,
  },
  {
    airline: "AirConnect",
    flightNumber: "AC 5101",
    departure: { time: "16:00", airport: "NRT" },
    arrival: { time: "09:00", airport: "LAX" },
    duration: "10h 0m",
    price: 585,
    stops: 0,
  },
  // LAX to NRT
  {
    airline: "GlobalAir",
    flightNumber: "GA 5200",
    departure: { time: "12:00", airport: "LAX" },
    arrival: { time: "16:00", airport: "NRT" },
    duration: "11h 0m",
    price: 575,
    stops: 0,
  },
  // HKG to SIN
  {
    airline: "AirConnect",
    flightNumber: "AC 4100",
    departure: { time: "09:00", airport: "HKG" },
    arrival: { time: "13:00", airport: "SIN" },
    duration: "4h 0m",
    price: 245,
    stops: 0,
  },
  {
    airline: "SkyWings",
    flightNumber: "SW 4101",
    departure: { time: "16:00", airport: "HKG" },
    arrival: { time: "20:00", airport: "SIN" },
    duration: "4h 0m",
    price: 225,
    stops: 0,
  },
  // BKK to HKG
  {
    airline: "GlobalAir",
    flightNumber: "GA 3100",
    departure: { time: "10:00", airport: "BKK" },
    arrival: { time: "13:30", airport: "HKG" },
    duration: "3h 30m",
    price: 195,
    stops: 0,
  },
  // HKG to BKK
  {
    airline: "AirConnect",
    flightNumber: "AC 3101",
    departure: { time: "14:00", airport: "HKG" },
    arrival: { time: "16:00", airport: "BKK" },
    duration: "3h 0m",
    price: 185,
    stops: 0,
  },
];

const Index = () => {
  const [searchParams, setSearchParams] = useState<{
    from: string;
    to: string;
    departDate: string;
    returnDate: string;
    passengers: string;
    tripType: "one-way" | "round-trip";
  } | null>(null);

  const [selectedOutbound, setSelectedOutbound] = useState<typeof mockFlights[0] | null>(null);

  const outboundFlights = searchParams
    ? mockFlights.filter(
        (flight) =>
          flight.departure.airport === searchParams.from &&
          flight.arrival.airport === searchParams.to
      )
    : [];

  const returnFlights = searchParams?.tripType === "round-trip"
    ? mockFlights.filter(
        (flight) =>
          flight.departure.airport === searchParams.to &&
          flight.arrival.airport === searchParams.from
      )
    : [];

  const handleSearch = (params: typeof searchParams) => {
    setSearchParams(params);
    setSelectedOutbound(null);
  };

  const handleOutboundSelect = (flight: typeof mockFlights[0]) => {
    setSelectedOutbound(flight);
  };

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="relative h-[600px] flex items-center justify-center overflow-hidden">
        <div
          className="absolute inset-0 bg-cover bg-center"
          style={{ backgroundImage: `url(${heroImage})` }}
        >
          <div className="absolute inset-0 bg-gradient-to-b from-background/80 via-background/60 to-background" />
        </div>

        <div className="relative z-10 container mx-auto px-4">
          <div className="flex justify-end items-center gap-4 mb-4">
            <CurrencySelector />
            <UserMenu />
          </div>
          
          <div className="text-center mb-8">
            <div className="flex items-center justify-center gap-2 mb-4">
              <Plane className="w-10 h-10 text-primary" />
              <h1 className="text-5xl font-bold">SkyWings Airlines</h1>
            </div>
            <p className="text-xl text-muted-foreground">
              Your trusted partner for comfortable flights worldwide
            </p>
          </div>

          <div className="max-w-4xl mx-auto">
            <FlightSearchForm onSearch={handleSearch} />
          </div>
        </div>
      </section>

      {/* Available Flights Section */}
      <section id="flight-results" className="py-16 bg-muted/30">
        <div className="container mx-auto px-4">
          {!searchParams ? (
            <div className="text-center py-12">
              <Plane className="w-16 h-16 text-muted-foreground mx-auto mb-4 opacity-50" />
              <h2 className="text-2xl font-semibold mb-2">Ready to fly?</h2>
              <p className="text-muted-foreground">
                Search for flights above to see available options
              </p>
            </div>
          ) : (
            <>
              {/* Outbound Flights */}
              <div className="mb-12">
            <h2 className="text-3xl font-bold mb-8">
              {searchParams
                ? `${searchParams.tripType === "round-trip" && !selectedOutbound ? "Select Outbound Flight: " : ""}${searchParams.from} to ${searchParams.to}`
                : "Available Flights"}
            </h2>
            <div className="space-y-4">
              {outboundFlights.length > 0 ? (
                outboundFlights.map((flight, index) => (
                  <FlightCard 
                    key={index} 
                    {...flight} 
                    passengers={searchParams?.passengers || "1"}
                    departureDate={searchParams?.departDate || ""}
                    onSelectOverride={searchParams?.tripType === "round-trip" ? () => handleOutboundSelect(flight) : undefined}
                  />
                ))
              ) : (
                <div className="text-center py-12">
                  <p className="text-xl text-muted-foreground mb-2">
                    No flights found for this route
                  </p>
                  <p className="text-sm text-muted-foreground">
                    Try searching for a different route or date
                  </p>
                </div>
              )}
              </div>
            </div>

            {/* Return Flights */}
            {searchParams?.tripType === "round-trip" && selectedOutbound && (
              <div id="return-flights">
                <h2 className="text-3xl font-bold mb-8">
                  Select Return Flight: {searchParams.to} to {searchParams.from}
                </h2>
                <div className="space-y-4">
                  {returnFlights.length > 0 ? (
                    returnFlights.map((flight, index) => (
                      <FlightCard 
                        key={index} 
                        {...flight} 
                        passengers={searchParams?.passengers || "1"}
                        departureDate={searchParams?.returnDate || ""}
                        outboundFlight={selectedOutbound}
                        outboundDepartureDate={searchParams?.departDate || ""}
                      />
                    ))
                  ) : (
                    <div className="text-center py-12">
                      <p className="text-xl text-muted-foreground mb-2">
                        No return flights found
                      </p>
                    </div>
                  )}
                </div>
              </div>
            )}
          </>
        )}
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-primary text-primary-foreground py-12">
        <div className="container mx-auto px-4 text-center">
          <div className="flex items-center justify-center gap-2 mb-4">
            <Plane className="w-6 h-6" />
            <span className="text-2xl font-bold">SkyWings Airlines</span>
          </div>
          <p className="text-primary-foreground/80">
            Your trusted partner for comfortable flights worldwide
          </p>
          <p className="text-primary-foreground/60 mt-4 text-sm">
            © 2025 SkyWings Airlines. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
};

export default Index;
