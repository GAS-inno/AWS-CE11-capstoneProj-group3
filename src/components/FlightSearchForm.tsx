import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { Plane, Calendar, Users } from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";

const airports = [
  { code: "JFK", name: "New York (JFK)", city: "New York" },
  { code: "LAX", name: "Los Angeles (LAX)", city: "Los Angeles" },
  { code: "SIN", name: "Singapore (SIN)", city: "Singapore" },
  { code: "LHR", name: "London (LHR)", city: "London" },
  { code: "DXB", name: "Dubai (DXB)", city: "Dubai" },
  { code: "HKG", name: "Hong Kong (HKG)", city: "Hong Kong" },
  { code: "NRT", name: "Tokyo (NRT)", city: "Tokyo" },
  { code: "CDG", name: "Paris (CDG)", city: "Paris" },
  { code: "SYD", name: "Sydney (SYD)", city: "Sydney" },
  { code: "BKK", name: "Bangkok (BKK)", city: "Bangkok" },
];

interface FlightSearchFormProps {
  onSearch?: (searchData: {
    from: string;
    to: string;
    departDate: string;
    returnDate: string;
    passengers: string;
    tripType: "one-way" | "round-trip";
  }) => void;
}

export const FlightSearchForm = ({ onSearch }: FlightSearchFormProps) => {
  const [searchData, setSearchData] = useState({
    from: "",
    to: "",
    departDate: "",
    returnDate: "",
    passengers: "1",
    tripType: "round-trip" as "one-way" | "round-trip",
  });

  const getTodayDate = () => {
    return new Date().toISOString().split("T")[0];
  };

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!searchData.from || !searchData.to) {
      toast.error("Please select both departure and destination airports");
      return;
    }
    
    if (searchData.from === searchData.to) {
      toast.error("Departure and destination airports must be different");
      return;
    }
    
    if (!searchData.departDate) {
      toast.error("Please select a departure date");
      return;
    }
    
    if (searchData.tripType === "round-trip" && !searchData.returnDate) {
      toast.error("Please select a return date for round-trip");
      return;
    }
    
    if (searchData.returnDate && searchData.returnDate <= searchData.departDate) {
      toast.error("Return date must be after departure date");
      return;
    }
    
    toast.success("Searching flights...");
    
    // Pass search data to parent
    if (onSearch) {
      onSearch(searchData);
    }
    
    // Scroll to results section
    const resultsSection = document.getElementById("flight-results");
    if (resultsSection) {
      resultsSection.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };

  return (
    <Card className="p-6 shadow-lg">
      <form onSubmit={handleSearch} className="space-y-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Trip Type</label>
          <RadioGroup
            value={searchData.tripType}
            onValueChange={(value: "one-way" | "round-trip") => 
              setSearchData({ ...searchData, tripType: value, returnDate: value === "one-way" ? "" : searchData.returnDate })
            }
            className="flex gap-4"
          >
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="round-trip" id="round-trip" />
              <Label htmlFor="round-trip">Round Trip</Label>
            </div>
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="one-way" id="one-way" />
              <Label htmlFor="one-way">One Way</Label>
            </div>
          </RadioGroup>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <label className="text-sm font-medium flex items-center gap-2">
              <Plane className="w-4 h-4" />
              From
            </label>
            <Select
              value={searchData.from}
              onValueChange={(value) => setSearchData({ ...searchData, from: value })}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select departure airport" />
              </SelectTrigger>
              <SelectContent>
                {airports.map((airport) => (
                  <SelectItem key={airport.code} value={airport.code}>
                    {airport.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium flex items-center gap-2">
              <Plane className="w-4 h-4 rotate-90" />
              To
            </label>
            <Select
              value={searchData.to}
              onValueChange={(value) => setSearchData({ ...searchData, to: value })}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select destination airport" />
              </SelectTrigger>
              <SelectContent>
                {airports.map((airport) => (
                  <SelectItem key={airport.code} value={airport.code}>
                    {airport.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="space-y-2">
            <label className="text-sm font-medium flex items-center gap-2">
              <Calendar className="w-4 h-4" />
              Departure
            </label>
            <Input
              type="date"
              min={getTodayDate()}
              value={searchData.departDate}
              onChange={(e) => setSearchData({ ...searchData, departDate: e.target.value })}
              required
            />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium flex items-center gap-2">
              <Calendar className="w-4 h-4" />
              Return {searchData.tripType === "round-trip" && <span className="text-destructive">*</span>}
            </label>
            <Input
              type="date"
              min={searchData.departDate || getTodayDate()}
              value={searchData.returnDate}
              onChange={(e) => setSearchData({ ...searchData, returnDate: e.target.value })}
              disabled={searchData.tripType === "one-way"}
              required={searchData.tripType === "round-trip"}
            />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium flex items-center gap-2">
              <Users className="w-4 h-4" />
              Passengers
            </label>
            <Input
              type="number"
              min="1"
              max="9"
              value={searchData.passengers}
              onChange={(e) => setSearchData({ ...searchData, passengers: e.target.value })}
              required
            />
          </div>
        </div>

        <Button type="submit" variant="accent" size="lg" className="w-full">
          Search Flights
        </Button>
      </form>
    </Card>
  );
};
