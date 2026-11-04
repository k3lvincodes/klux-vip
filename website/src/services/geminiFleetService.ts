export type FleetCategory = 'None' | 'Sedans' | 'SUVs' | 'Vans' | 'Buses' | 'Business Class' | 'Business Van' | 'First Class';

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
  year?: number
): { category: FleetCategory; reason: string } {
  const text = `${make} ${model}`.toLowerCase();
  const y = typeof year === 'number' && !isNaN(year) && year > 1900 ? year : new Date().getFullYear();

  // 2. Business Van
  // Examples: Mercedes-Benz V-Class, Volkswagen Multivan, Toyota Alphard, Lexus LM.
  const isVanOrMpv =
    text.includes('van') ||
    text.includes('v-class') ||
    text.includes('v class') ||
    text.includes('vclass') ||
    text.includes('multivan') ||
    text.includes('alphard') ||
    text.includes('lexus lm') ||
    text.includes('lm 350') ||
    text.includes('lm 500') ||
    text.includes('lm350') ||
    text.includes('lm500') ||
    text.includes('vellfire') ||
    text.includes('vito') ||
    text.includes('sprinter') ||
    text.includes('transit') ||
    text.includes('caravelle') ||
    text.includes('metris') ||
    text.includes('escalade') ||
    text.includes('suburban') ||
    text.includes('navigator') ||
    text.includes('yukon') ||
    text.includes('tahoe');

  if (isVanOrMpv) {
    const yearNote = y < 2019 ? ` (Model year ${y} is below 2019+ requirement)` : '';
    return {
      category: 'Business Van',
      reason: `Luxury passenger van / MPV • 5–7 passengers • 4+ suitcases${yearNote}`,
    };
  }

  // 3. First Class
  // Examples: Mercedes-Benz S-Class, Mercedes-Maybach, BMW 7 Series, Audi A8, Lexus LS, Porsche Panamera.
  const isFlagshipSedan =
    text.includes('s-class') ||
    text.includes('s class') ||
    text.includes('sclass') ||
    text.includes('maybach') ||
    text.includes('s 580') ||
    text.includes('s 680') ||
    text.includes('s580') ||
    text.includes('s680') ||
    text.includes('7 series') ||
    text.includes('7-series') ||
    text.includes('740') ||
    text.includes('750') ||
    text.includes('760') ||
    text.includes('i7') ||
    text.includes('a8') ||
    text.includes('s8') ||
    text.includes('lexus ls') ||
    text.includes('ls 500') ||
    text.includes('ls500') ||
    text.includes('ls 600') ||
    text.includes('panamera') ||
    text.includes('flying spur') ||
    text.includes('phantom') ||
    text.includes('ghost') ||
    text.includes('rolls') ||
    text.includes('bentley') ||
    text.includes('eqs');

  if (isFlagshipSedan && y >= 2021) {
    return {
      category: 'First Class',
      reason: `Flagship luxury sedan • Model year ${y} (2021+) • Max 3 passengers • Ultra-luxury`,
    };
  }

  if (isFlagshipSedan && y < 2021) {
    return {
      category: 'Business Class',
      reason: `Flagship sedan model year ${y} (First Class requires 2021+) • Classified as Business Class`,
    };
  }

  // 1. Business Class
  // Examples: Mercedes-Benz E-Class, BMW 5 Series, Audi A6, Lexus ES, Genesis G80.
  const yearNote = y < 2019 ? ` (Model year ${y} is below 2019+ requirement)` : '';
  return {
    category: 'Business Class',
    reason: `Executive sedan • Max 3 passengers • 2 medium suitcases${yearNote}`,
  };
}

/**
 * Sends vehicle details directly to Google Gemini AI to evaluate and classify into:
 * - "First Class"
 * - "Business Van"
 * - "Business Class"
 * adhering strictly to the Kenick VIP fleet criteria.
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
- Examples: Mercedes-Benz V-Class, Toyota Alphard, Toyota Vellfire, Lexus LM, Chevrolet Suburban, GMC Yukon XL.

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
        } else if (parsed.category === 'Vans' || parsed.category === 'Van' || parsed.category === 'Business Van') {
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
