class AirportDetectionService {
  static const Map<String, String> _knownAirportCodes = {
    'ind': 'IND',
    'indianapolis': 'IND',
    'lax': 'LAX',
    'los angeles': 'LAX',
    'jfk': 'JFK',
    'john f kennedy': 'JFK',
    'kennedy': 'JFK',
    'lga': 'LGA',
    'laguardia': 'LGA',
    'ewr': 'EWR',
    'newark': 'EWR',
    'ord': 'ORD',
    'o\'hare': 'ORD',
    'ohare': 'ORD',
    'chicago o\'hare': 'ORD',
    'mdw': 'MDW',
    'midway': 'MDW',
    'sfo': 'SFO',
    'san francisco': 'SFO',
    'oak': 'OAK',
    'oakland': 'OAK',
    'sjc': 'SJC',
    'san jose': 'SJC',
    'sea': 'SEA',
    'seattle': 'SEA',
    'tacoma': 'SEA',
    'atl': 'ATL',
    'atlanta': 'ATL',
    'hartsfield': 'ATL',
    'dfw': 'DFW',
    'dallas': 'DFW',
    'love field': 'DAL',
    'dal': 'DAL',
    'mia': 'MIA',
    'miami': 'MIA',
    'fll': 'FLL',
    'fort lauderdale': 'FLL',
    'mco': 'MCO',
    'orlando': 'MCO',
    'tpa': 'TPA',
    'tampa': 'TPA',
    'bos': 'BOS',
    'boston': 'BOS',
    'logan': 'BOS',
    'iad': 'IAD',
    'dulles': 'IAD',
    'dca': 'DCA',
    'reagan': 'DCA',
    'bwi': 'BWI',
    'baltimore': 'BWI',
    'phx': 'PHX',
    'phoenix': 'PHX',
    'sky harbor': 'PHX',
    'den': 'DEN',
    'denver': 'DEN',
    'iah': 'IAH',
    'houston': 'IAH',
    'george bush': 'IAH',
    'hou': 'HOU',
    'hobby': 'HOU',
    'las': 'LAS',
    'las vegas': 'LAS',
    'harry reid': 'LAS',
    'mccarran': 'LAS',
    'phl': 'PHL',
    'philadelphia': 'PHL',
    'clt': 'CLT',
    'charlotte': 'CLT',
    'dtw': 'DTW',
    'detroit': 'DTW',
    'msp': 'MSP',
    'minneapolis': 'MSP',
    'san': 'SAN',
    'san diego': 'SAN',
    'slc': 'SLC',
    'salt lake': 'SLC',
    'bna': 'BNA',
    'nashville': 'BNA',
    'aus': 'AUS',
    'austin': 'AUS',
    'rdu': 'RDU',
    'raleigh': 'RDU',
    'cvg': 'CVG',
    'cincinnati': 'CVG',
    'cle': 'CLE',
    'cleveland': 'CLE',
    'cmh': 'CMH',
    'columbus': 'CMH',
    'pit': 'PIT',
    'pittsburgh': 'PIT',
    'mke': 'MKE',
    'milwaukee': 'MKE',
    'mci': 'MCI',
    'kansas city': 'MCI',
    'stl': 'STL',
    'st louis': 'STL',
    'mem': 'MEM',
    'memphis': 'MEM',
    'msy': 'MSY',
    'new orleans': 'MSY',
    'lhr': 'LHR',
    'heathrow': 'LHR',
    'lgw': 'LGW',
    'gatwick': 'LGW',
    'cdg': 'CDG',
    'charles de gaulle': 'CDG',
    'dxb': 'DXB',
    'dubai': 'DXB',
    'ams': 'AMS',
    'schiphol': 'AMS',
    'fra': 'FRA',
    'frankfurt': 'FRA',
    'muc': 'MUC',
    'munich': 'MUC',
    'zrh': 'ZRH',
    'zurich': 'ZRH',
    'yyz': 'YYZ',
    'toronto pearson': 'YYZ',
  };

  /// Returns true if the address represents an airport or aviation terminal
  static bool isAirport(String? address) {
    if (address == null || address.trim().isEmpty) return false;
    final lower = address.toLowerCase();

    // 1. Direct airport / aviation keywords
    if (lower.contains('airport') ||
        lower.contains('aeroport') ||
        lower.contains('flughafen') ||
        lower.contains('aeropuerto') ||
        lower.contains('airfield') ||
        lower.contains('airstrip') ||
        lower.contains('heliport') ||
        lower.contains('terminal 1') ||
        lower.contains('terminal 2') ||
        lower.contains('terminal 3') ||
        lower.contains('terminal 4') ||
        lower.contains('terminal 5') ||
        lower.contains('intl air') ||
        lower.contains('signature flight') ||
        lower.contains('atlantic aviation') ||
        lower.contains('million air') ||
        lower.contains('fbo') ||
        lower.contains('private jet terminal') ||
        lower.contains('executive terminal')) {
      return true;
    }

    // 2. Check uppercase 3-letter IATA code pattern (e.g. "(IND)", "IND Airport", "at LAX")
    final parenRegex = RegExp(r'\(([A-Z]{3})\)');
    final parenMatch = parenRegex.firstMatch(address);
    if (parenMatch != null) {
      final code = parenMatch.group(1)!.toLowerCase();
      if (_knownAirportCodes.containsKey(code)) {
        return true;
      }
    }

    final wordRegex = RegExp(r'\b([A-Z]{3})\b');
    final wordMatches = wordRegex.allMatches(address);
    for (final m in wordMatches) {
      final code = m.group(1)!.toLowerCase();
      if (_knownAirportCodes.containsKey(code)) {
        return true;
      }
    }

    return false;
  }

  /// Alias for extractAirportCodeOrName
  static String extractAirportCode(String? address) => extractAirportCodeOrName(address);

  /// Extracts the standard 3-letter IATA code or short airport identifier (e.g., 'IND', 'LAX', 'JFK')
  static String extractAirportCodeOrName(String? address) {
    if (address == null || address.trim().isEmpty) return 'IND';

    // 1. Check parenthesized uppercase code e.g. (IND)
    final parenRegex = RegExp(r'\(([A-Z]{3})\)');
    final parenMatch = parenRegex.firstMatch(address);
    if (parenMatch != null) {
      return parenMatch.group(1)!;
    }

    // 2. Check 3-letter uppercase words that match recognized IATA codes
    final wordRegex = RegExp(r'\b([A-Z]{3})\b');
    final wordMatches = wordRegex.allMatches(address);
    for (final m in wordMatches) {
      final code = m.group(1)!;
      if (_knownAirportCodes.containsKey(code.toLowerCase())) {
        return code;
      }
    }

    // 3. Check city/airport name substring match
    final lower = address.toLowerCase();
    for (final entry in _knownAirportCodes.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 4. Fallback: extract primary location token before comma
    final commaIdx = address.indexOf(',');
    final firstPart = (commaIdx > 0 ? address.substring(0, commaIdx) : address).trim();
    if (firstPart.isNotEmpty && firstPart.length <= 15) {
      return firstPart.toUpperCase();
    }

    return 'IND';
  }
}

