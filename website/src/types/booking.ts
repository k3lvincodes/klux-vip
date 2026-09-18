export const STEPS = {
  TRIP: 1,
  FARE: 2,
  CHAUFFEUR: 3,
  PAYMENT: 4,
  CONFIRMATION: 5,
} as const;
export type Step = typeof STEPS[keyof typeof STEPS];

export interface AssignedChauffeur {
  id: string;
  name: string;
  avatarUrl?: string;
  phone: string;
  rating: number;
  tripsCount: number;
  yearsExperience: number;
  vehicleName: string;
  licensePlate: string;
  color: string;
}

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
  pickupCoords?: { lat: number; lng: number };
  dropoffCoords?: { lat: number; lng: number };
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
  chauffeur?: AssignedChauffeur;
}
