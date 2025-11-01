import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useCurrency, currencies } from "@/contexts/CurrencyContext";

export const CurrencySelector = () => {
  const { currency, setCurrency } = useCurrency();

  return (
    <div className="flex items-center gap-2">
      <Select
        value={currency.code}
        onValueChange={(code) => {
          const selectedCurrency = currencies.find((c) => c.code === code);
          if (selectedCurrency) {
            setCurrency(selectedCurrency);
          }
        }}
      >
        <SelectTrigger className="w-[140px]">
          <SelectValue placeholder="Currency" />
        </SelectTrigger>
        <SelectContent>
          {currencies.map((curr) => (
            <SelectItem key={curr.code} value={curr.code}>
              {curr.symbol} {curr.code}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
};
