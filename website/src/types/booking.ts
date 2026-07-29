export const STEPS = { TRIP: 1, FARE: 2, PAYMENT: 3, CONFIRMATION: 4 } as const;
export type Step = typeof STEPS[keyof typeof STEPS];

export interface BookingFormData {
  pickup: string;
  dropoff: string;
  date: string;
  time: string;
  vehicle: string;
  passengers: string;
  name: string;
  email: string;
  phone: string;
}

export interface FareBreakdown {
  baseFare: number;
  tripFare: number;
  subtotal: number;
  tip: number;
  total: number;
}

export interface BookingConfirmation {
  invoiceNumber: string;
  confirmationNumber: string;
  pickup: string;
  dropoff: string;
  date: string;
  time: string;
  vehicle: string;
  baseFare: number;
  tip: number;
  tax: number;
  total: number;
}
