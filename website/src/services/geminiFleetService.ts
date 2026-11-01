export type FleetCategory = 'None' | 'Business Class' | 'Business Van' | 'First Class';

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
Categorize the given vehicle into exactly ONE of these 3 VIP categories based strictly on these criteria:

1. Business Class
- Purpose: Premium everyday business transportation
- Vehicle type: Executive sedan
- Seating: 3 passengers maximum
- Doors: 4
- Model year: 2019 or newer
- Luggage: Minimum 2 medium suitcases
- Safety: Functional airbags, ABS, stability control
- Appearance: Excellent condition
- Examples: Mercedes-Benz E-Class, BMW 5 Series, Audi A6, Lexus ES, Genesis G80.

2. Business Van
- Purpose: Group transportation, corporate travel and airport transfers
- Vehicle type: Luxury passenger van / MPV
- Seating: 5–7 passengers
- Doors: 4 or more
- Model year: 2019 or newer
- Luggage: Minimum 4 medium suitcases
- Safety: Functional airbags, ABS, stability control
- Appearance: Excellent exterior and interior condition
- Examples: Mercedes-Benz V-Class, Volkswagen Multivan, Toyota Alphard, Lexus LM.

3. First Class
- Purpose: Ultra-premium transportation for executives, VIPs and high-profile clients
- Vehicle type: Flagship luxury sedan
- Seating: 3 passengers maximum
- Doors: 4
- Model year: 2021 or newer (Strict: If a flagship sedan is older than 2021, categorize as Business Class instead)
- Interior: Full luxury/premium leather, exceptional passenger comfort, multi-zone climate control
- Safety: Advanced driver assistance systems
- Appearance: Immaculate condition
- Examples: Mercedes-Benz S-Class, Mercedes-Maybach, BMW 7 Series, Audi A8, Lexus LS, Porsche Panamera.

VEHICLE TO CATEGORIZE:
- Make: ${vehicle.make || 'Unknown'}
- Model: ${vehicle.model || 'Unknown'}
- Year: ${vehicle.year || 'Unknown'}
- Features: ${vehicle.features || 'Standard Luxury Chauffeur Package'}

Respond ONLY with valid JSON in this exact structure:
{
  "category": "First Class" | "Business Van" | "Business Class",
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

        let validatedCategory: FleetCategory = 'Business Class';
        if (parsed.category === 'First Class') {
          validatedCategory = 'First Class';
        } else if (parsed.category === 'Business Van') {
          validatedCategory = 'Business Van';
        } else {
          validatedCategory = 'Business Class';
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
