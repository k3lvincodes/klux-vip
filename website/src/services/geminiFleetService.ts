export type FleetCategory = 'None' | 'Sedans' | 'SUVs' | 'Vans' | 'Buses';

export interface VehicleCategorizationResult {
  category: FleetCategory;
  reason: string;
  evaluatedByGemini: boolean;
}

const GEMINI_API_KEY =
  (import.meta.env.VITE_GEMINI_API_KEY as string | undefined)?.trim() || '';

// Deterministic rule engine fallback if Gemini is offline or unreachable
export function categorizeVehicleFallback(
  make: string,
  model: string,
  _year?: number
): { category: FleetCategory; reason: string } {
  const text = `${make} ${model}`.toLowerCase();

  // 1. Buses: Minibuses, Coaches, High-capacity Shuttles (highest tier)
  const isBus =
    text.includes('bus') ||
    text.includes('minibus') ||
    text.includes('coach') ||
    text.includes('coaster') ||
    text.includes('rosa') ||
    text.includes('tourliner') ||
    text.includes('setra') ||
    text.includes('sprinter 15') ||
    text.includes('sprinter 16') ||
    text.includes('sprinter 18') ||
    text.includes('sprinter 20') ||
    text.includes('transit 15') ||
    text.includes('transit 14') ||
    text.includes('crafter 16') ||
    text.includes('intercity');

  if (isBus) {
    return {
      category: 'Buses',
      reason: 'VIP executive coach / minibus • High capacity delegation transport (16+ pax)',
    };
  }

  // 2. Vans: Executive MPVs, Passenger Vans, Standard Sprinters
  const isVan =
    text.includes('van') ||
    text.includes('v-class') ||
    text.includes('v class') ||
    text.includes('vclass') ||
    text.includes('vito') ||
    text.includes('sprinter') ||
    text.includes('transit') ||
    text.includes('multivan') ||
    text.includes('caravelle') ||
    text.includes('metris') ||
    text.includes('alphard') ||
    text.includes('vellfire') ||
    text.includes('carnival') ||
    text.includes('sienna') ||
    text.includes('odyssey') ||
    text.includes('pacifica') ||
    text.includes('transporter') ||
    text.includes('hiace') ||
    text.includes('granvia') ||
    text.includes('staria') ||
    text.includes('h-1') ||
    text.includes('lexus lm') ||
    text.includes('lm 350') ||
    text.includes('lm 500') ||
    text.includes('lm350') ||
    text.includes('lm500');

  if (isVan) {
    return {
      category: 'Vans',
      reason: 'Luxury passenger MPV / van • Executive group transfer (up to 7 pax)',
    };
  }

  // 3. SUVs: Full-size & luxury SUVs
  const isSuv =
    text.includes('suv') ||
    text.includes('escalade') ||
    text.includes('suburban') ||
    text.includes('tahoe') ||
    text.includes('yukon') ||
    text.includes('navigator') ||
    text.includes('expedition') ||
    text.includes('range rover') ||
    text.includes('land cruiser') ||
    text.includes('lexus lx') ||
    text.includes('lx 600') ||
    text.includes('lx 570') ||
    text.includes('lx600') ||
    text.includes('lx570') ||
    text.includes('gls') ||
    text.includes('gle') ||
    text.includes('g-wagon') ||
    text.includes('g63') ||
    text.includes('g-class') ||
    text.includes('g class') ||
    text.includes('x7') ||
    text.includes('x5') ||
    text.includes('q7') ||
    text.includes('q8') ||
    text.includes('cullinan') ||
    text.includes('bentayga') ||
    text.includes('urus');

  if (isSuv) {
    return {
      category: 'SUVs',
      reason: 'Prestige luxury SUV • Elevated road presence and comfort (up to 5 pax)',
    };
  }

  // 4. Sedans: Executive & Luxury sedans (lowest pricing baseline)
  return {
    category: 'Sedans',
    reason: 'Executive luxury sedan • Quiet, refined chauffeur ride (up to 3 pax)',
  };
}

/**
 * Sends vehicle details directly to Google Gemini AI to evaluate and classify into:
 * - "Sedans"
 * - "SUVs"
 * - "Vans"
 * - "Buses"
 * adhering strictly to the official Kenick VIP fleet criteria.
 */
export async function categorizeVehicleWithGemini(vehicle: {
  make: string;
  model: string;
  year?: number;
  features?: string | null;
}): Promise<VehicleCategorizationResult> {
  const apiKey = GEMINI_API_KEY;

  if (!apiKey) {
    console.warn('[Gemini AI] No VITE_GEMINI_API_KEY configured. Falling back to local rule engine.');
    const fallback = categorizeVehicleFallback(vehicle.make, vehicle.model, vehicle.year);
    return { ...fallback, evaluatedByGemini: false };
  }

  const systemInstructions = `
You are Kenick AI, the Chief Fleet Inspection AI for Kenick VIP, a world-class luxury chauffeur service.
Categorize the given vehicle into exactly ONE of these 4 VIP categories based strictly on these criteria:

1. Sedans (Baseline / Lowest Pricing)
- Purpose: Premium executive and luxury sedan transportation
- Vehicle type: Executive or flagship sedan
- Seating: 3-4 passengers
- Luggage: 2-3 medium suitcases
- Examples: Mercedes-Benz E-Class, S-Class, BMW 5/7 Series, Audi A6/A8, Lexus ES/LS, Genesis G80/G90.

2. SUVs (Premium Pricing - ~25% above Sedans)
- Purpose: Elevated comfort, high road presence, family or executive VIP travel
- Vehicle type: Luxury SUV
- Seating: 4-6 passengers
- Luggage: 3-5 suitcases
- Examples: Cadillac Escalade, Range Rover, Mercedes-Benz GLE/GLS/G-Wagon, BMW X5/X7, Audi Q7/Q8, Lincoln Navigator.

3. Vans (Executive Group Pricing - ~45% above Sedans)
- Purpose: Corporate delegation travel, airport group transfers, luxury touring
- Vehicle type: Luxury passenger van / MPV
- Seating: 6-8 passengers
- Luggage: 5-8 suitcases
- Examples: Mercedes-Benz V-Class, Toyota Alphard, Toyota Vellfire, Lexus LM.

4. Buses (Maximum Capacity & Highest Pricing - ~80% above Sedans)
- Purpose: Large group transportation, events, VIP shuttle operations
- Vehicle type: Executive minibus, luxury coach, passenger van 10+ pax
- Seating: 9-24+ passengers
- Luggage: 10+ suitcases
- Examples: Mercedes-Benz Sprinter Passenger (12-15 seater), Ford Transit Minibus, Toyota Coaster, VIP Executive Coach.

VEHICLE TO CATEGORIZE:
- Make: ${vehicle.make || 'Unknown'}
- Model: ${vehicle.model || 'Unknown'}
- Year: ${vehicle.year || 'Unknown'}
- Features: ${vehicle.features || 'Standard Luxury Chauffeur Package'}

Respond ONLY with valid JSON in this exact structure:
{
  "category": "Sedans" | "SUVs" | "Vans" | "Buses",
  "reason": "1-2 concise sentences explaining why the vehicle meets the criteria for this category"
}
`;

  // Try primary fast model, then fallback model if needed
  const modelsToTry = ['gemini-3.1-flash-lite', 'gemini-3.8-flash', 'gemini-flash-latest'];

  for (const modelName of modelsToTry) {
    try {
      console.log(`[Kenick AI] Evaluating ${vehicle.make} ${vehicle.model} (${vehicle.year}) using ${modelName}...`);
      const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${encodeURIComponent(
        apiKey
      )}`;

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 12000);

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: systemInstructions }] }],
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.2,
          },
        }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorText = await response.text();
        console.warn(`[Kenick AI] Model ${modelName} returned status ${response.status}: ${errorText}`);
        continue;
      }

      const json = await response.json();
      const rawText = json?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';

      if (rawText) {
        // Strip markdown code fences if model included them
        const cleaned = rawText.replace(/```json/g, '').replace(/```/g, '').trim();
        const parsed = JSON.parse(cleaned);

        let validatedCategory: FleetCategory = 'Sedans';
        if (parsed.category === 'Buses' || parsed.category === 'Bus') {
          validatedCategory = 'Buses';
        } else if (parsed.category === 'Vans' || parsed.category === 'Van') {
          validatedCategory = 'Vans';
        } else if (parsed.category === 'SUVs' || parsed.category === 'SUV') {
          validatedCategory = 'SUVs';
        } else {
          validatedCategory = 'Sedans';
        }

        const reason =
          typeof parsed.reason === 'string' && parsed.reason.trim()
            ? parsed.reason.trim()
            : `Classified by Kenick AI as ${validatedCategory}.`;

        console.log(`[Kenick AI] Live AI classification complete for ${vehicle.make} ${vehicle.model}:`, {
          category: validatedCategory,
          reason,
          model: modelName
        });

        return {
          category: validatedCategory,
          reason,
          evaluatedByGemini: true,
        };
      }
    } catch (err) {
      console.warn(`[Kenick AI] Request to ${modelName} failed:`, err);
    }
  }

  // If all Gemini calls fail or timeout, fall back to rule engine
  const fallback = categorizeVehicleFallback(vehicle.make, vehicle.model, vehicle.year);
  return { ...fallback, evaluatedByGemini: false };
}
