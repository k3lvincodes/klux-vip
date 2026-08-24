import { useState, useEffect, useMemo } from 'react';
import { supabase } from '../../lib/supabase';
import { Search, ChevronDown, Plus, X, Globe, TrendingUp, MapPin, DollarSign, RotateCcw } from 'lucide-react';

interface CountryState {
  name: string;
  vipAmount: number;
  inherited: boolean;
}

interface SelectedCountry {
  code: string;
  name: string;
  flag: string;
  currencySymbol: string;
  vipAmount: number;
  perKmRate: number;
  baseFare: number;
  perMinuteRate: number;
  states: CountryState[];
  expanded: boolean;
}

interface FareRate {
  id: string;
  country_code: string;
  state_or_region: string | null;
  vip_amount: number | null;
  per_km_rate: number | null;
  base_fare: number | null;
  per_minute_rate: number | null;
}



const COUNTRIES: { code: string; name: string; flag: string; states: string[] }[] = [
  { code: 'US', name: 'United States', flag: '🇺🇸', states: ['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'] },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧', states: ['England', 'Scotland', 'Wales', 'Northern Ireland'] },
  { code: 'CA', name: 'Canada', flag: '🇨🇦', states: ['Alberta', 'British Columbia', 'Manitoba', 'New Brunswick', 'Newfoundland and Labrador', 'Nova Scotia', 'Ontario', 'Prince Edward Island', 'Quebec', 'Saskatchewan', 'Northwest Territories', 'Nunavut', 'Yukon'] },
  { code: 'AU', name: 'Australia', flag: '🇦🇺', states: ['New South Wales', 'Victoria', 'Queensland', 'Western Australia', 'South Australia', 'Tasmania', 'Australian Capital Territory', 'Northern Territory'] },
  { code: 'NG', name: 'Nigeria', flag: '🇳🇬', states: ['Lagos', 'Abuja FCT', 'Rivers', 'Kano', 'Oyo', 'Kaduna', 'Delta', 'Edo', 'Ogun', 'Anambra', 'Akwa Ibom', 'Enugu', 'Benue', 'Kwara', 'Imo', 'Abia', 'Nasarawa', 'Plateau', 'Borno', 'Bauchi', 'Osun', 'Sokoto', 'Katsina', 'Zamfara', 'Cross River', 'Ondo', 'Ekiti', 'Kogi', 'Ebonyi', 'Gombe', 'Taraba', 'Adamawa', 'Yobe', 'Jigawa', 'Kebbi', 'Niger', 'Bayelsa'] },
  { code: 'BR', name: 'Brazil', flag: '🇧🇷', states: ['São Paulo', 'Rio de Janeiro', 'Minas Gerais', 'Bahia', 'Rio Grande do Sul', 'Paraná', 'Pernambuco', 'Ceará', 'Pará', 'Maranhão', 'Santa Catarina', 'Goiás', 'Amazonas', 'Espírito Santo', 'Rio Grande do Norte', 'Alagoas', 'Mato Grosso', 'Mato Grosso do Sul', 'Distrito Federal', 'Paraíba', 'Piauí', 'Sergipe', 'Rondônia', 'Tocantins', 'Amapá', 'Roraima', 'Acre'] },
  { code: 'DE', name: 'Germany', flag: '🇩🇪', states: ['Bavaria', 'North Rhine-Westphalia', 'Baden-Württemberg', 'Lower Saxony', 'Hesse', 'Berlin', 'Schleswig-Holstein', 'Brandenburg', 'Saxony', 'Rhineland-Palatinate', 'Thuringia', 'Hamburg', 'Saxony-Anhalt', 'Mecklenburg-Vorpommern', 'Saarland', 'Bremen'] },
  { code: 'FR', name: 'France', flag: '🇫🇷', states: ['Île-de-France', 'Auvergne-Rhône-Alpes', 'Nouvelle-Aquitaine', 'Occitanie', 'Hauts-de-France', "Provence-Alpes-Côte d'Azur", 'Bretagne', 'Normandie', 'Pays de la Loire', 'Grand Est', 'Bourgogne-Franche-Comté', 'Centre-Val de Loire', 'Corse'] },
  { code: 'ES', name: 'Spain', flag: '🇪🇸', states: ['Andalusia', 'Catalonia', 'Madrid', 'Valencia', 'Basque Country', 'Galicia', 'Castile and León', 'Aragon', 'Balearic Islands', 'Canary Islands', 'Murcia', 'Navarre', 'Extremadura', 'Castilla-La Mancha', 'Asturias', 'La Rioja', 'Cantabria'] },
  { code: 'IT', name: 'Italy', flag: '🇮🇹', states: ['Lombardy', 'Lazio', 'Campania', 'Sicily', 'Veneto', 'Emilia-Romagna', 'Piedmont', 'Apulia', 'Tuscany', 'Calabria', 'Sardinia', 'Liguria', 'Marche', 'Abruzzo', 'Friuli-Venezia Giulia', 'Trentino-Alto Adige', 'Umbria', 'Basilicata', 'Molise', 'Aosta Valley'] },
  { code: 'NL', name: 'Netherlands', flag: '🇳🇱', states: ['North Holland', 'South Holland', 'North Brabant', 'Gelderland', 'Utrecht', 'Overijssel', 'Limburg', 'Flevoland', 'Groningen', 'Drenthe', 'Friesland', 'Zeeland'] },
  { code: 'AE', name: 'United Arab Emirates', flag: '🇦🇪', states: ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Ras Al Khaimah', 'Fujairah', 'Umm Al Quwain'] },
  { code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', states: ['Riyadh', 'Makkah', 'Madinah', 'Eastern Province', 'Asir', 'Tabuk', 'Qassim', 'Hail', 'Jazan', 'Najran', 'Al Bahah', 'Al Jawf', 'Northern Borders'] },
  { code: 'ZA', name: 'South Africa', flag: '🇿🇦', states: ['Gauteng', 'Western Cape', 'KwaZulu-Natal', 'Eastern Cape', 'Mpumalanga', 'Limpopo', 'North West', 'Free State', 'Northern Cape'] },
  { code: 'EG', name: 'Egypt', flag: '🇪🇬', states: ['Cairo', 'Alexandria', 'Giza', 'Port Said', 'Suez', 'Luxor', 'Aswan', 'Sharm El-Sheikh', 'Hurghada', 'Mansoura', 'Tanta', 'Ismailia', 'Damietta'] },
  { code: 'KE', name: 'Kenya', flag: '🇰🇪', states: ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret', 'Thika', 'Malindi', 'Nyeri', 'Machakos', 'Meru'] },
  { code: 'GH', name: 'Ghana', flag: '🇬🇭', states: ['Greater Accra', 'Ashanti', 'Western', 'Eastern', 'Central', 'Volta', 'Northern', 'Upper East', 'Upper West', 'Bono', 'Ahafo', 'Bono East', 'Oti', 'North East', 'Savannah', 'Western North'] },
  { code: 'IN', name: 'India', flag: '🇮🇳', states: ['Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu', 'Uttar Pradesh', 'Gujarat', 'Rajasthan', 'West Bengal', 'Telangana', 'Andhra Pradesh', 'Kerala', 'Madhya Pradesh', 'Haryana', 'Punjab', 'Bihar', 'Odisha', 'Assam', 'Chandigarh', 'Goa'] },
  { code: 'CN', name: 'China', flag: '🇨🇳', states: ['Beijing', 'Shanghai', 'Guangdong', 'Shenzhen', 'Jiangsu', 'Zhejiang', 'Sichuan', 'Hubei', 'Fujian', 'Hunan', 'Anhui', 'Henan', 'Shandong', 'Tianjin', 'Chongqing'] },
  { code: 'JP', name: 'Japan', flag: '🇯🇵', states: ['Tokyo', 'Osaka', 'Kanagawa', 'Aichi', 'Saitama', 'Chiba', 'Hyogo', 'Hokkaido', 'Fukuoka', 'Shizuoka', 'Ibaraki', 'Hiroshima', 'Kyoto', 'Miyagi', 'Niigata', 'Gunma'] },
  { code: 'KR', name: 'South Korea', flag: '🇰🇷', states: ['Seoul', 'Busan', 'Incheon', 'Daegu', 'Daejeon', 'Gwangju', 'Suwon', 'Ulsan', 'Seongnam', 'Goyang', 'Changwon', 'Yongin'] },
  { code: 'SG', name: 'Singapore', flag: '🇸🇬', states: ['Central', 'East', 'North', 'North-East', 'West'] },
  { code: 'MY', name: 'Malaysia', flag: '🇲🇾', states: ['Kuala Lumpur', 'Selangor', 'Johor', 'Penang', 'Sabah', 'Sarawak', 'Perak', 'Pahang', 'Negeri Sembilan', 'Malacca', 'Kedah', 'Terengganu', 'Kelantan', 'Perlis', 'Labuan', 'Putrajaya'] },
  { code: 'TH', name: 'Thailand', flag: '🇹🇭', states: ['Bangkok', 'Phuket', 'Chon Buri', 'Chiang Mai', 'Samut Prakan', 'Nonthaburi', 'Pathum Thani', 'Songkhla', 'Surat Thani', 'Krabi'] },
  { code: 'VN', name: 'Vietnam', flag: '🇻🇳', states: ['Ho Chi Minh City', 'Hanoi', 'Da Nang', 'Hai Phong', 'Can Tho', 'Binh Duong', 'Dong Nai', 'Ba Ria-Vung Tau', 'Quang Ninh', 'Thua Thien Hue', 'Khanh Hoa', 'Lam Dong'] },
  { code: 'PH', name: 'Philippines', flag: '🇵🇭', states: ['Metro Manila', 'Cebu', 'Davao', 'Cavite', 'Laguna', 'Rizal', 'Batangas', 'Pampanga', 'Bulacan', 'Negros Occidental', 'Iloilo', 'Pangasinan'] },
  { code: 'ID', name: 'Indonesia', flag: '🇮🇩', states: ['Jakarta', 'West Java', 'East Java', 'Central Java', 'North Sumatra', 'Bali', 'South Sulawesi', 'Banten', 'Lampung', 'Riau', 'South Sumatra', 'Yogyakarta', 'East Kalimantan'] },
  { code: 'TR', name: 'Turkey', flag: '🇹🇷', states: ['Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Antalya', 'Mersin', 'Adana', 'Gaziantep', 'Konya', 'Kayseri', 'Diyarbakir', 'Eskisehir', 'Trabzon'] },
  { code: 'RU', name: 'Russia', flag: '🇷🇺', states: ['Moscow', 'Saint Petersburg', 'Moscow Oblast', 'Krasnodar Krai', 'Sverdlovsk Oblast', 'Tatarstan', 'Bashkortostan', 'Chelyabinsk Oblast', 'Nizhny Novgorod Oblast', 'Rostov Oblast', 'Samara Oblast', 'Krasnoyarsk Krai', 'Voronezh Oblast'] },
  { code: 'MX', name: 'Mexico', flag: '🇲🇽', states: ['Mexico City', 'State of Mexico', 'Jalisco', 'Nuevo León', 'Puebla', 'Guanajuato', 'Chihuahua', 'Baja California', 'Veracruz', 'Yucatán', 'Quintana Roo', 'Sinaloa', 'Sonora', 'Michoacán', 'Oaxaca', 'Chiapas', 'Tamaulipas', 'Coahuila', 'Hidalgo', 'Tabasco'] },
  { code: 'AR', name: 'Argentina', flag: '🇦🇷', states: ['Buenos Aires', 'Córdoba', 'Santa Fe', 'Mendoza', 'Tucumán', 'Entre Ríos', 'Salta', 'Chaco', 'Corrientes', 'Misiones', 'Santiago del Estero', 'San Juan', 'Río Negro', 'Neuquén', 'Formosa', 'Chubut', 'San Luis', 'La Pampa', 'Catamarca', 'La Rioja', 'Santa Cruz', 'Tierra del Fuego', 'Jujuy'] },
  { code: 'CL', name: 'Chile', flag: '🇨🇱', states: ['Santiago', 'Valparaíso', 'Biobío', 'Los Lagos', 'Araucanía', 'Coquimbo', 'Antofagasta', 'Maule', "O'Higgins", 'Los Ríos', 'Arica y Parinacota', 'Tarapacá', 'Atacama', 'Magallanes', 'Ñuble'] },
  { code: 'CO', name: 'Colombia', flag: '🇨🇴', states: ['Bogotá', 'Antioquia', 'Valle del Cauca', 'Cundinamarca', 'Atlántico', 'Santander', 'Bolívar', 'Nariño', 'Cauca', 'Magdalena', 'Boyacá', 'Caldas', 'Risaralda', 'Quindío', 'Meta', 'Córdoba', 'Sucre', 'Norte de Santander'] },
  { code: 'PT', name: 'Portugal', flag: '🇵🇹', states: ['Lisbon', 'Porto', 'Braga', 'Coimbra', 'Aveiro', 'Faro', 'Madeira', 'Azores', 'Setúbal', 'Viseu', 'Leiria', 'Évora', 'Santarém', 'Vila Real'] },
  { code: 'IE', name: 'Ireland', flag: '🇮🇪', states: ['Dublin', 'Cork', 'Galway', 'Limerick', 'Waterford', 'Kilkenny', 'Drogheda', 'Dundalk', 'Bray', 'Swords', 'Navan', 'Tralee'] },
  { code: 'SE', name: 'Sweden', flag: '🇸🇪', states: ['Stockholm', 'Västra Götaland', 'Skåne', 'Uppsala', 'Östergötland', 'Jönköping', 'Dalarna', 'Gävleborg', 'Västmanland', 'Norrbotten', 'Västerbotten', 'Halland', 'Södermanland', 'Värmland'] },
  { code: 'NO', name: 'Norway', flag: '🇳🇴', states: ['Oslo', 'Viken', 'Vestland', 'Trøndelag', 'Rogaland', 'Innlandet', 'Agder', 'Møre og Romsdal', 'Troms og Finnmark', 'Nordland', 'Vestfold og Telemark'] },
  { code: 'DK', name: 'Denmark', flag: '🇩🇰', states: ['Capital Region', 'Central Denmark', 'Southern Denmark', 'North Denmark', 'Zealand'] },
  { code: 'FI', name: 'Finland', flag: '🇫🇮', states: ['Uusimaa', 'Pirkanmaa', 'Southwest Finland', 'Northern Ostrobothnia', 'Central Finland', 'Satakunta', 'South Karelia', 'Lapland', 'Päijät-Häme', 'Kymenlaakso', 'Etelä-Savo', 'North Karelia'] },
  { code: 'CH', name: 'Switzerland', flag: '🇨🇭', states: ['Zürich', 'Bern', 'Vaud', 'Aargau', 'St. Gallen', 'Geneva', 'Lucerne', 'Ticino', 'Basel-Stadt', 'Basel-Landschaft', 'Fribourg', 'Valais', 'Graubünden', 'Solothurn', 'Thurgau', 'Neuchâtel', 'Schwyz', 'Zug', 'Schaffhausen', 'Jura'] },
  { code: 'AT', name: 'Austria', flag: '🇦🇹', states: ['Vienna', 'Lower Austria', 'Upper Austria', 'Styria', 'Tyrol', 'Carinthia', 'Salzburg', 'Vorarlberg', 'Burgenland'] },
  { code: 'BE', name: 'Belgium', flag: '🇧🇪', states: ['Flemish Region', 'Walloon Region', 'Brussels-Capital Region'] },
  { code: 'PL', name: 'Poland', flag: '🇵🇱', states: ['Masovia', 'Lesser Poland', 'Silesia', 'Greater Poland', 'Lower Silesia', 'Lodz', 'Pomerania', 'Lublin', 'West Pomerania', 'Kuyavia-Pomerania', 'Podkarpacie', 'Warmia-Masuria', 'Swietokrzyskie', 'Podlaskie', 'Lubusz', 'Opole'] },
  { code: 'GR', name: 'Greece', flag: '🇬🇷', states: ['Attica', 'Central Macedonia', 'Thessaly', 'Western Greece', 'Crete', 'Eastern Macedonia and Thrace', 'Peloponnese', 'Epirus', 'Central Greece', 'South Aegean', 'North Aegean', 'Ionian Islands'] },
  { code: 'CZ', name: 'Czech Republic', flag: '🇨🇿', states: ['Prague', 'Central Bohemia', 'South Moravia', 'Moravia-Silesia', 'Plzeň', 'Liberec', 'Olomouc', 'South Bohemia', 'Ústí nad Labem', 'Hradec Králové', 'Zlín', 'Karlovy Vary', 'Vysočina', 'Pardubice'] },
  { code: 'HU', name: 'Hungary', flag: '🇭🇺', states: ['Budapest', 'Pest', 'Borsod-Abaúj-Zemplén', 'Hajdú-Bihar', 'Bács-Kiskun', 'Győr-Moson-Sopron', 'Szabolcs-Szatmár-Bereg', 'Csongrád-Csanád', 'Baranya', 'Jász-Nagykun-Szolnok', 'Veszprém', 'Fejér', 'Békés', 'Tolna', 'Somogy', 'Vas', 'Heves', 'Nógrád', 'Zala', 'Komárom-Esztergom'] },
  { code: 'RO', name: 'Romania', flag: '🇷🇴', states: ['Bucharest', 'Cluj', 'Timiș', 'Iași', 'Constanța', 'Brașov', 'Galați', 'Dolj', 'Bihor', 'Prahova', 'Argeș', 'Sibiu', 'Mureș', 'Bacău', 'Maramureș', 'Arad', 'Suceava', 'Neamț', 'Olt', 'Vâlcea'] },
  { code: 'IL', name: 'Israel', flag: '🇮🇱', states: ['Tel Aviv', 'Jerusalem', 'Haifa', 'Central District', 'Southern District', 'Northern District'] },
  { code: 'QA', name: 'Qatar', flag: '🇶🇦', states: ['Doha', 'Al Rayyan', 'Al Wakrah', 'Umm Salal', 'Al Khor', 'Al Shamal', 'Al Daayen'] },
  { code: 'KW', name: 'Kuwait', flag: '🇰🇼', states: ['Al Asimah', 'Hawalli', 'Farwaniya', 'Ahmadi', 'Jahra', 'Mubarak Al-Kabeer'] },
  { code: 'OM', name: 'Oman', flag: '🇴🇲', states: ['Muscat', 'Dhofar', 'Musandam', 'Al Buraimi', 'Ad Dakhiliyah', 'Al Batinah North', 'Al Batinah South', 'Ash Sharqiyah North', 'Ash Sharqiyah South', 'Adh Dhahirah', 'Al Wusta'] },
  { code: 'JO', name: 'Jordan', flag: '🇯🇴', states: ['Amman', 'Zarqa', 'Irbid', 'Balqa', 'Aqaba', 'Madaba', 'Mafraq', 'Karak', 'Tafilah', "Ma'an", 'Jerash', 'Ajloun'] },
  { code: 'MA', name: 'Morocco', flag: '🇲🇦', states: ['Casablanca-Settat', 'Rabat-Salé-Kénitra', 'Marrakech-Safi', 'Fès-Meknès', 'Tangier-Tetouan-Al Hoceima', 'Souss-Massa', 'Oriental', 'Drâa-Tafilalet', 'Béni Mellal-Khénifra', 'Guelmim-Oued Noun', 'Laâyoune-Sakia El Hamra', 'Dakhla-Oued Ed-Dahab'] },
  { code: 'DZ', name: 'Algeria', flag: '🇩🇿', states: ['Algiers', 'Oran', 'Constantine', 'Annaba', 'Blida', 'Sétif', 'Tlemcen', 'Béjaïa', 'Batna', 'Sidi Bel Abbès', 'Biskra', 'Tizi Ouzou', 'Chlef', 'Boumerdès', 'Médéa', 'Ouargla', 'Mostaganem', 'Skikda', 'Mascara', 'El Oued'] },
  { code: 'TZ', name: 'Tanzania', flag: '🇹🇿', states: ['Dar es Salaam', 'Mwanza', 'Arusha', 'Mbeya', 'Zanzibar', 'Tanga', 'Morogoro', 'Kilimanjaro', 'Iringa', 'Dodoma', 'Mtwara', 'Kigoma', 'Tabora', 'Shinyanga', 'Rukwa', 'Songwe'] },
  { code: 'UG', name: 'Uganda', flag: '🇺🇬', states: ['Kampala', 'Wakiso', 'Mukono', 'Mbale', 'Mbarara', 'Gulu', 'Jinja', 'Lira', 'Masaka', 'Kasese', 'Hoima', 'Arua', 'Busia', 'Soroti', 'Kabarole'] },
  { code: 'ET', name: 'Ethiopia', flag: '🇪🇹', states: ['Addis Ababa', 'Oromia', 'Amhara', 'Southern Nations', 'Tigray', 'Sidama', 'Afar', 'Somali', 'Benishangul-Gumuz', 'Gambela', 'Harari'] },
  { code: 'CM', name: 'Cameroon', flag: '🇨🇲', states: ['Yaoundé', 'Douala', 'Garoua', 'Bamenda', 'Maroua', 'Bafoussam', 'Nkongsamba', 'Kribi', 'Limbe', 'Ebolowa'] },
  { code: 'CI', name: "Côte d'Ivoire", flag: '🇨🇮', states: ['Abidjan', 'Yamoussoukro', 'Bouaké', 'Daloa', 'San-Pédro', 'Korhogo', 'Man', 'Gagnoa', 'Divo', 'Anyama'] },
  { code: 'SN', name: 'Senegal', flag: '🇸🇳', states: ['Dakar', 'Thiès', 'Diourbel', 'Saint-Louis', 'Kaolack', 'Ziguinchor', 'Louga', 'Fatick', 'Kolda', 'Kédougou', 'Kaffrine', 'Matam', 'Sédhiou', 'Tambacounda'] },
  { code: 'PK', name: 'Pakistan', flag: '🇵🇰', states: ['Sindh', 'Punjab', 'Khyber Pakhtunkhwa', 'Balochistan', 'Islamabad', 'Azad Kashmir', 'Gilgit-Baltistan'] },
  { code: 'BD', name: 'Bangladesh', flag: '🇧🇩', states: ['Dhaka', 'Chittagong', 'Khulna', 'Rajshahi', 'Sylhet', 'Barisal', 'Rangpur', 'Mymensingh'] },
  { code: 'LK', name: 'Sri Lanka', flag: '🇱🇰', states: ['Western Province', 'Central Province', 'Southern Province', 'Northern Province', 'Eastern Province', 'North Western Province', 'North Central Province', 'Uva Province', 'Sabaragamuwa Province'] },
  { code: 'NZ', name: 'New Zealand', flag: '🇳🇿', states: ['Auckland', 'Wellington', 'Canterbury', 'Waikato', 'Bay of Plenty', 'Otago', 'Manawatu-Whanganui', "Hawke's Bay", 'Taranaki', 'Southland', 'Northland', 'Tasman', 'Marlborough', 'West Coast', 'Nelson', 'Gisborne'] },
  { code: 'PE', name: 'Peru', flag: '🇵🇪', states: ['Lima', 'Arequipa', 'Cusco', 'La Libertad', 'Lambayeque', 'Piura', 'Junín', 'Cajamarca', 'San Martín', 'Puno', 'Ica', 'Ancash', 'Callao', 'Loreto', 'Tacna', 'Ucayali', 'Huánuco', 'Ayacucho', 'Apurímac', 'Amazonas', 'Huancavelica', 'Moquegua', 'Pasco', 'Tumbes', 'Madre de Dios'] },
  { code: 'UA', name: 'Ukraine', flag: '🇺🇦', states: ['Kyiv', 'Kharkiv', 'Dnipro', 'Odesa', 'Lviv', 'Mykolaiv', 'Zaporizhzhia', 'Vinnytsia', 'Poltava', 'Chernihiv', 'Sumy', 'Zhytomyr', 'Cherkasy', 'Rivne', 'Ivano-Frankivsk', 'Khmelnytskyi', 'Ternopil', 'Volyn', 'Kirovohrad', 'Chernivtsi', 'Zakarpattia'] },
  { code: 'KZ', name: 'Kazakhstan', flag: '🇰🇿', states: ['Almaty', 'Astana', 'Shymkent', 'Karaganda', 'Aktobe', 'Pavlodar', 'East Kazakhstan', 'Atyrau', 'Kostanay', 'West Kazakhstan', 'Kyzylorda', 'Mangystau', 'Turkistan', 'North Kazakhstan', 'Abai', 'Zhetysu', 'Ulytau'] },
];

const COUNTRY_CURRENCY: Record<string, { symbol: string; code: string }> = {
  US: { symbol: '$', code: 'USD' },
  GB: { symbol: '£', code: 'GBP' },
  CA: { symbol: 'CA$', code: 'CAD' },
  AU: { symbol: 'A$', code: 'AUD' },
  NG: { symbol: '₦', code: 'NGN' },
  BR: { symbol: 'R$', code: 'BRL' },
  DE: { symbol: '€', code: 'EUR' },
  FR: { symbol: '€', code: 'EUR' },
  ES: { symbol: '€', code: 'EUR' },
  IT: { symbol: '€', code: 'EUR' },
  NL: { symbol: '€', code: 'EUR' },
  PT: { symbol: '€', code: 'EUR' },
  IE: { symbol: '€', code: 'EUR' },
  BE: { symbol: '€', code: 'EUR' },
  AT: { symbol: '€', code: 'EUR' },
  GR: { symbol: '€', code: 'EUR' },
  FI: { symbol: '€', code: 'EUR' },
  EE: { symbol: '€', code: 'EUR' },
  LV: { symbol: '€', code: 'EUR' },
  LT: { symbol: '€', code: 'EUR' },
  SK: { symbol: '€', code: 'EUR' },
  SI: { symbol: '€', code: 'EUR' },
  MT: { symbol: '€', code: 'EUR' },
  CY: { symbol: '€', code: 'EUR' },
  AE: { symbol: 'د.إ', code: 'AED' },
  SA: { symbol: '﷼', code: 'SAR' },
  QA: { symbol: '﷼', code: 'QAR' },
  KW: { symbol: 'د.ك', code: 'KWD' },
  OM: { symbol: '﷼', code: 'OMR' },
  JO: { symbol: 'د.ا', code: 'JOD' },
  IL: { symbol: '₪', code: 'ILS' },
  ZA: { symbol: 'R', code: 'ZAR' },
  EG: { symbol: 'E£', code: 'EGP' },
  KE: { symbol: 'KSh', code: 'KES' },
  GH: { symbol: 'GH₵', code: 'GHS' },
  TZ: { symbol: 'TSh', code: 'TZS' },
  UG: { symbol: 'USh', code: 'UGX' },
  ET: { symbol: 'Br', code: 'ETB' },
  CM: { symbol: 'FCFA', code: 'XAF' },
  CI: { symbol: 'FCFA', code: 'XOF' },
  SN: { symbol: 'FCFA', code: 'XOF' },
  MA: { symbol: 'د.م.', code: 'MAD' },
  DZ: { symbol: 'د.ج', code: 'DZD' },
  IN: { symbol: '₹', code: 'INR' },
  PK: { symbol: 'Rs', code: 'PKR' },
  BD: { symbol: '৳', code: 'BDT' },
  LK: { symbol: 'Rs', code: 'LKR' },
  CN: { symbol: '¥', code: 'CNY' },
  JP: { symbol: '¥', code: 'JPY' },
  KR: { symbol: '₩', code: 'KRW' },
  SG: { symbol: 'S$', code: 'SGD' },
  MY: { symbol: 'RM', code: 'MYR' },
  TH: { symbol: '฿', code: 'THB' },
  VN: { symbol: '₫', code: 'VND' },
  PH: { symbol: '₱', code: 'PHP' },
  ID: { symbol: 'Rp', code: 'IDR' },
  TR: { symbol: '₺', code: 'TRY' },
  RU: { symbol: '₽', code: 'RUB' },
  MX: { symbol: 'MX$', code: 'MXN' },
  AR: { symbol: 'AR$', code: 'ARS' },
  CL: { symbol: 'CL$', code: 'CLP' },
  CO: { symbol: 'CO$', code: 'COP' },
  PE: { symbol: 'S/.', code: 'PEN' },
  NZ: { symbol: 'NZ$', code: 'NZD' },
  PL: { symbol: 'zł', code: 'PLN' },
  CZ: { symbol: 'Kč', code: 'CZK' },
  HU: { symbol: 'Ft', code: 'HUF' },
  RO: { symbol: 'lei', code: 'RON' },
  SE: { symbol: 'kr', code: 'SEK' },
  NO: { symbol: 'kr', code: 'NOK' },
  DK: { symbol: 'kr', code: 'DKK' },
  CH: { symbol: 'CHF', code: 'CHF' },
  UA: { symbol: '₴', code: 'UAH' },
  KZ: { symbol: '₸', code: 'KZT' },
};

const CURRENCY_DEFAULTS: Record<string, { perKmRate: number; baseFare: number; perMinuteRate: number }> = {
  USD: { perKmRate: 1.85, baseFare: 3.5, perMinuteRate: 0.45 },
  GBP: { perKmRate: 1.45, baseFare: 2.8, perMinuteRate: 0.35 },
  CAD: { perKmRate: 2.45, baseFare: 4.5, perMinuteRate: 0.6 },
  AUD: { perKmRate: 2.75, baseFare: 5.0, perMinuteRate: 0.65 },
  NGN: { perKmRate: 250, baseFare: 500, perMinuteRate: 80 },
  BRL: { perKmRate: 3.5, baseFare: 7.0, perMinuteRate: 0.9 },
  EUR: { perKmRate: 1.7, baseFare: 3.2, perMinuteRate: 0.42 },
  AED: { perKmRate: 3.0, baseFare: 12.0, perMinuteRate: 0.5 },
  SAR: { perKmRate: 3.0, baseFare: 12.0, perMinuteRate: 0.5 },
  QAR: { perKmRate: 3.0, baseFare: 12.0, perMinuteRate: 0.5 },
  KWD: { perKmRate: 0.6, baseFare: 1.2, perMinuteRate: 0.15 },
  OMR: { perKmRate: 0.5, baseFare: 1.0, perMinuteRate: 0.12 },
  JOD: { perKmRate: 0.6, baseFare: 1.2, perMinuteRate: 0.15 },
  ILS: { perKmRate: 6.5, baseFare: 12.0, perMinuteRate: 1.6 },
  ZAR: { perKmRate: 12.0, baseFare: 25.0, perMinuteRate: 3.0 },
  EGP: { perKmRate: 25.0, baseFare: 50.0, perMinuteRate: 8.0 },
  KES: { perKmRate: 80.0, baseFare: 150.0, perMinuteRate: 25.0 },
  GHS: { perKmRate: 8.0, baseFare: 15.0, perMinuteRate: 2.5 },
  TZS: { perKmRate: 1200, baseFare: 2500, perMinuteRate: 400 },
  UGX: { perKmRate: 2500, baseFare: 5000, perMinuteRate: 800 },
  ETB: { perKmRate: 55.0, baseFare: 100.0, perMinuteRate: 18.0 },
  XAF: { perKmRate: 750, baseFare: 1500, perMinuteRate: 250 },
  XOF: { perKmRate: 750, baseFare: 1500, perMinuteRate: 250 },
  MAD: { perKmRate: 10.0, baseFare: 20.0, perMinuteRate: 3.0 },
  DZD: { perKmRate: 65.0, baseFare: 120.0, perMinuteRate: 20.0 },
  INR: { perKmRate: 45.0, baseFare: 80.0, perMinuteRate: 12.0 },
  PKR: { perKmRate: 180, baseFare: 350, perMinuteRate: 55 },
  BDT: { perKmRate: 80.0, baseFare: 150.0, perMinuteRate: 25.0 },
  LKR: { perKmRate: 300, baseFare: 600, perMinuteRate: 90 },
  CNY: { perKmRate: 8.0, baseFare: 15.0, perMinuteRate: 2.5 },
  JPY: { perKmRate: 200, baseFare: 400, perMinuteRate: 60 },
  KRW: { perKmRate: 2500, baseFare: 5000, perMinuteRate: 800 },
  SGD: { perKmRate: 2.5, baseFare: 4.5, perMinuteRate: 0.6 },
  MYR: { perKmRate: 4.5, baseFare: 8.0, perMinuteRate: 1.2 },
  THB: { perKmRate: 35.0, baseFare: 65.0, perMinuteRate: 10.0 },
  VND: { perKmRate: 15000, baseFare: 30000, perMinuteRate: 4500 },
  PHP: { perKmRate: 55.0, baseFare: 100.0, perMinuteRate: 16.0 },
  IDR: { perKmRate: 8000, baseFare: 15000, perMinuteRate: 2500 },
  TRY: { perKmRate: 35.0, baseFare: 65.0, perMinuteRate: 10.0 },
  RUB: { perKmRate: 80.0, baseFare: 150.0, perMinuteRate: 25.0 },
  MXN: { perKmRate: 25.0, baseFare: 45.0, perMinuteRate: 7.0 },
  ARS: { perKmRate: 800, baseFare: 1500, perMinuteRate: 250 },
  CLP: { perKmRate: 1000, baseFare: 2000, perMinuteRate: 300 },
  COP: { perKmRate: 3500, baseFare: 7000, perMinuteRate: 1100 },
  PEN: { perKmRate: 4.5, baseFare: 8.0, perMinuteRate: 1.2 },
  NZD: { perKmRate: 2.9, baseFare: 5.5, perMinuteRate: 0.7 },
  PLN: { perKmRate: 7.5, baseFare: 14.0, perMinuteRate: 2.0 },
  CZK: { perKmRate: 45.0, baseFare: 85.0, perMinuteRate: 13.0 },
  HUF: { perKmRate: 700, baseFare: 1300, perMinuteRate: 200 },
  RON: { perKmRate: 8.5, baseFare: 16.0, perMinuteRate: 2.5 },
  SEK: { perKmRate: 12.0, baseFare: 22.0, perMinuteRate: 3.5 },
  NOK: { perKmRate: 13.0, baseFare: 24.0, perMinuteRate: 3.8 },
  DKK: { perKmRate: 9.0, baseFare: 17.0, perMinuteRate: 2.7 },
  CHF: { perKmRate: 2.0, baseFare: 3.8, perMinuteRate: 0.5 },
  UAH: { perKmRate: 35.0, baseFare: 65.0, perMinuteRate: 10.0 },
  KZT: { perKmRate: 500, baseFare: 1000, perMinuteRate: 150 },
};

function getCurrency(countryCode: string) {
  return COUNTRY_CURRENCY[countryCode] || { symbol: '$', code: 'USD' };
}

function getDefaultRates(countryCode: string) {
  const currency = getCurrency(countryCode);
  return CURRENCY_DEFAULTS[currency.code] || CURRENCY_DEFAULTS.USD;
}

const SELECTED_COUNTRY_CODES = ['US', 'GB', 'CA', 'AU', 'NG', 'BR'];

export default function PricingPage() {
  const [selectedCountries, setSelectedCountries] = useState<SelectedCountry[]>([]);
  const [showModal, setShowModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [modalError, setModalError] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);

  useEffect(() => {
    loadCountries();
  }, []);

  async function loadCountries() {
    setLoading(true);
    setError(null);
    try {
      const { data, error } = await supabase.from('fare_rates').select('*').order('country_code');
      if (error) throw error;
      const dbRates = (data as FareRate[] | null) || [];

      const grouped = new Map<string, FareRate[]>();
      for (const r of dbRates) {
        const key = r.country_code.toUpperCase();
        if (!grouped.has(key)) grouped.set(key, []);
        grouped.get(key)!.push(r);
      }

      const countryMap = new Map(COUNTRIES.map(c => [c.code, c]));
      const result: SelectedCountry[] = [];
      const processed = new Set<string>();

      const countryCodes = grouped.size > 0
        ? [...grouped.keys()]
        : SELECTED_COUNTRY_CODES;

      for (const code of countryCodes) {
        if (processed.has(code)) continue;
        const info = countryMap.get(code);
        if (!info) continue;
        processed.add(code);

        const existing = grouped.get(code);
        const countryDefault = existing?.find(r => !r.state_or_region);
        const stateRates = existing?.filter(r => r.state_or_region) || [];

        const defaults = getDefaultRates(code);

        result.push({
          code,
          name: info.name,
          flag: info.flag,
          currencySymbol: getCurrency(code).symbol,
          vipAmount: countryDefault?.vip_amount ?? 0,
          perKmRate: countryDefault?.per_km_rate ?? defaults.perKmRate,
          baseFare: countryDefault?.base_fare ?? defaults.baseFare,
          perMinuteRate: countryDefault?.per_minute_rate ?? defaults.perMinuteRate,
          states: info.states.map(s => {
            const match = stateRates.find(r => r.state_or_region === s);
            return {
              name: s,
              vipAmount: match?.vip_amount ?? countryDefault?.vip_amount ?? 0,
              inherited: !match,
            };
          }),
          expanded: false,
        });
      }

      setSelectedCountries(result);
    } catch (err) {
      setError('Failed to load pricing data');
    } finally {
      setLoading(false);
    }
  }

  async function addCountry(code: string) {
    const info = COUNTRIES.find(c => c.code === code);
    if (!info) return;
    if (selectedCountries.some(c => c.code === code)) return;

    setAdding(true);
    setModalError('');

    const defaults = getDefaultRates(code);

    const newCountry: SelectedCountry = {
      code,
      name: info.name,
      flag: info.flag,
      currencySymbol: getCurrency(code).symbol,
      vipAmount: 0,
      perKmRate: defaults.perKmRate,
      baseFare: defaults.baseFare,
      perMinuteRate: defaults.perMinuteRate,
      states: info.states.map(s => ({ name: s, vipAmount: 0, inherited: true })),
      expanded: false,
    };

    const { error } = await supabase.from('fare_rates').insert({
      country_code: code.toLowerCase(),
      state_or_region: null,
      per_km_rate: defaults.perKmRate,
      base_fare: defaults.baseFare,
      per_minute_rate: defaults.perMinuteRate,
      vip_amount: 0,
    });

    if (error) {
      setModalError(error.message || 'Failed to add country. Please try again.');
      setAdding(false);
      return;
    }

    setSelectedCountries(prev => [...prev, newCountry]);
    setShowModal(false);
    setSearchQuery('');
    setAdding(false);
  }

  async function removeCountry(code: string) {
    const { error } = await supabase.from('fare_rates').delete().eq('country_code', code.toLowerCase());
    if (error) return;
    setSelectedCountries(prev => prev.filter(c => c.code !== code));
  }

  async function updateCountryRates(code: string, patch: { perKmRate?: number; baseFare?: number; perMinuteRate?: number }) {
    const { data: existing } = await supabase
      .from('fare_rates')
      .select('id')
      .eq('country_code', code.toLowerCase())
      .is('state_or_region', null)
      .maybeSingle();

    const dbPatch: Partial<Record<string, number>> = {};
    if (patch.perKmRate !== undefined) dbPatch.per_km_rate = patch.perKmRate;
    if (patch.baseFare !== undefined) dbPatch.base_fare = patch.baseFare;
    if (patch.perMinuteRate !== undefined) dbPatch.per_minute_rate = patch.perMinuteRate;

    let error;
    if (existing) {
      ({ error } = await supabase.from('fare_rates').update(dbPatch).eq('id', existing.id));
    } else {
      const defaults = getDefaultRates(code);
      ({ error } = await supabase.from('fare_rates').insert({
        country_code: code.toLowerCase(),
        state_or_region: null,
        vip_amount: 0,
        per_km_rate: patch.perKmRate ?? defaults.perKmRate,
        base_fare: patch.baseFare ?? defaults.baseFare,
        per_minute_rate: patch.perMinuteRate ?? defaults.perMinuteRate,
      }));
    }

    if (error) return;
    setSelectedCountries(prev => prev.map(c => (c.code === code ? { ...c, ...patch } : c)));
  }

  async function updateStateVip(code: string, stateName: string, amount: number) {
    const { data: existing } = await supabase
      .from('fare_rates')
      .select('id')
      .eq('country_code', code.toLowerCase())
      .eq('state_or_region', stateName)
      .maybeSingle();

    let error;
    if (existing) {
      ({ error } = await supabase.from('fare_rates').update({ vip_amount: amount }).eq('id', existing.id));
    } else {
      const defaults = getDefaultRates(code);
      ({ error } = await supabase.from('fare_rates').insert({
        country_code: code.toLowerCase(),
        state_or_region: stateName,
        vip_amount: amount,
        per_km_rate: defaults.perKmRate,
        base_fare: defaults.baseFare,
        per_minute_rate: defaults.perMinuteRate,
      }));
    }

    if (error) return;

    setSelectedCountries(prev =>
      prev.map(c =>
        c.code === code
          ? { ...c, states: c.states.map(s => s.name === stateName ? { ...s, vipAmount: amount, inherited: false } : s) }
          : c
      )
    );
  }

  async function resetStateToInherit(code: string, stateName: string) {
    const { error } = await supabase
      .from('fare_rates')
      .delete()
      .eq('country_code', code.toLowerCase())
      .eq('state_or_region', stateName);

    if (error) return;

    setSelectedCountries(prev =>
      prev.map(c =>
        c.code === code
          ? { ...c, states: c.states.map(s => s.name === stateName ? { ...s, vipAmount: c.vipAmount, inherited: true } : s) }
          : c
      )
    );
  }

  function toggleExpand(code: string) {
    setSelectedCountries(prev =>
      prev.map(c => c.code === code ? { ...c, expanded: !c.expanded } : c)
    );
  }

  const filteredCountries = useMemo(() => {
    const selectedCodes = new Set(selectedCountries.map(c => c.code));
    return COUNTRIES.filter(
      c =>
        !selectedCodes.has(c.code) &&
        (c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          c.code.toLowerCase().includes(searchQuery.toLowerCase()))
    );
  }, [searchQuery, selectedCountries]);

  // Computed stats
  const totalRegions = selectedCountries.reduce((sum, c) => sum + c.states.length, 0);
  const customRegions = selectedCountries.reduce(
    (sum, c) => sum + c.states.filter(s => !s.inherited).length,
    0
  );

  if (loading) {
    return (
      <div className="pricing-page">
        <div className="admin-page-header">
          <div>
            <h1>VIP Country Pricing</h1>
            <p>Manage VIP pricing by country and region.</p>
          </div>
        </div>
        <div style={{ textAlign: 'center', padding: '5rem', color: 'var(--admin-text-muted)' }}>
          {error ? (
            <div>
              <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error}</p>
              <button className="admin-btn" onClick={loadCountries}>Try Again</button>
            </div>
          ) : (
            <div className="pricing-loading">
              <div className="pricing-loading-spinner" />
              <p>Loading pricing data…</p>
            </div>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="pricing-page">
      {/* ── Page Header ── */}
      <div className="admin-page-header">
        <div>
          <h1>VIP Country Pricing</h1>
          <p>Configure fare rates per country and region worldwide.</p>
        </div>
        <button onClick={() => setShowModal(true)} className="admin-btn">
          <Plus size={16} />
          Add Country
        </button>
      </div>

      {/* ── Stats Bar ── */}
      <div className="pricing-stats-bar">
        <div className="pricing-stat-card">
          <div className="pricing-stat-icon" style={{ background: 'rgba(244, 197, 34, 0.12)', color: '#F4C522' }}>
            <Globe size={18} />
          </div>
          <div>
            <div className="pricing-stat-value">{selectedCountries.length}</div>
            <div className="pricing-stat-label">Countries</div>
          </div>
        </div>
        <div className="pricing-stat-card">
          <div className="pricing-stat-icon" style={{ background: 'rgba(16, 185, 129, 0.12)', color: '#10b981' }}>
            <MapPin size={18} />
          </div>
          <div>
            <div className="pricing-stat-value">{totalRegions.toLocaleString()}</div>
            <div className="pricing-stat-label">Regions Covered</div>
          </div>
        </div>
        <div className="pricing-stat-card">
          <div className="pricing-stat-icon" style={{ background: 'rgba(99, 102, 241, 0.12)', color: '#818cf8' }}>
            <DollarSign size={18} />
          </div>
          <div>
            <div className="pricing-stat-value">{selectedCountries.filter(c => c.vipAmount > 0).length}</div>
            <div className="pricing-stat-label">Countries with VIP Rate</div>
          </div>
        </div>
        <div className="pricing-stat-card">
          <div className="pricing-stat-icon" style={{ background: 'rgba(249, 115, 22, 0.12)', color: '#fb923c' }}>
            <TrendingUp size={18} />
          </div>
          <div>
            <div className="pricing-stat-value">{customRegions}</div>
            <div className="pricing-stat-label">Custom Overrides</div>
          </div>
        </div>
      </div>

      {/* ── Country Cards ── */}
      {selectedCountries.length === 0 ? (
        <div className="pricing-empty">
          <div className="pricing-empty-icon">🌍</div>
          <h3>No countries configured</h3>
          <p>Add your first country to start managing VIP pricing for your markets.</p>
          <button onClick={() => setShowModal(true)} className="admin-btn">
            <Plus size={16} /> Add Country
          </button>
        </div>
      ) : (
        <div className="vip-country-grid">
          {selectedCountries.map(country => (
            <div key={country.code} className={`vip-country-card ${country.expanded ? 'expanded' : ''}`}>

              {/* Card Header */}
              <div className="vip-country-header" onClick={() => toggleExpand(country.code)}>
                <div className="vip-country-info">
                  <span className="vip-country-flag">{country.flag}</span>
                  <div>
                    <span className="vip-country-name">{country.name}</span>
                    <span className="vip-country-code">{country.code} · {country.states.length} regions</span>
                  </div>
                </div>

                <div className="pricing-header-right">
                  {/* VIP Amount pill */}
                  <div className="pricing-vip-pill">
                    <span className="pricing-vip-label">Base</span>
                    <span className="vip-currency">{country.currencySymbol}</span>
                    <span className="vip-amount-display">{country.baseFare.toFixed(2)}</span>
                  </div>

                  <button
                    className="vip-remove-btn"
                    onClick={e => { e.stopPropagation(); removeCountry(country.code); }}
                    title="Remove country"
                  >
                    <X size={14} />
                  </button>

                  <div className={`vip-chevron ${country.expanded ? 'open' : ''}`}>
                    <ChevronDown size={18} />
                  </div>
                </div>
              </div>

              {/* Accordion Body */}
              <div className={`vip-accordion-wrapper ${country.expanded ? 'open' : ''}`}>
                <div className="vip-accordion-inner">

                  {/* Base Fare Rates */}
                  <div className="pricing-rates-section">
                    <div className="pricing-section-label">
                      <DollarSign size={13} />
                      Base Fare Rates
                    </div>
                    <div className="pricing-rates-grid">
                      {[
                        { label: 'Per km', key: 'perKmRate' as const, value: country.perKmRate },
                        { label: 'Base fare', key: 'baseFare' as const, value: country.baseFare },
                        { label: 'Per minute', key: 'perMinuteRate' as const, value: country.perMinuteRate },
                      ].map(f => (
                        <div key={f.key} className="pricing-rate-card">
                          <div className="pricing-rate-label">{f.label}</div>
                          <div className="pricing-rate-input-wrap">
                            <span className="pricing-rate-prefix">{country.currencySymbol}</span>
                            <input
                              type="number"
                              step="0.01"
                              min="0"
                              value={f.value}
                              onChange={e => updateCountryRates(country.code, { [f.key]: parseFloat(e.target.value) || 0 })}
                              className="pricing-rate-input"
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Regional Overrides */}
                  <div className="pricing-states-section">
                    <div className="pricing-section-label" style={{ marginBottom: '0.65rem' }}>
                      <MapPin size={13} />
                      Regions / States
                      <span className="pricing-section-hint">Blank regions inherit country default</span>
                    </div>
                    <div className="pricing-states-list">
                      {[...country.states].sort((a, b) => a.name.localeCompare(b.name)).map(state => (
                        <div key={state.name} className="pricing-state-row">
                          <span className="vip-state-name">{state.name}</span>
                          <div className="pricing-state-right">
                            {state.inherited ? (
                              <span className="pricing-inherited-badge">auto · {country.currencySymbol}{state.vipAmount.toFixed(2)}</span>
                            ) : (
                              <button
                                className="pricing-reset-btn"
                                onClick={() => resetStateToInherit(country.code, state.name)}
                                title="Reset to country default"
                              >
                                <RotateCcw size={11} />
                              </button>
                            )}
                            <div className="pricing-state-input-wrap">
                            <span className="pricing-rate-prefix">{country.currencySymbol}</span>
                              <input
                                type="number"
                                step="0.01"
                                min="0"
                                value={state.vipAmount}
                                onChange={e => updateStateVip(country.code, state.name, parseFloat(e.target.value) || 0)}
                                className={`pricing-state-input ${state.inherited ? 'inherited' : 'custom'}`}
                              />
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── Add Country Modal ── */}
      {showModal && (
        <div className="admin-modal-overlay" onClick={() => { setShowModal(false); setSearchQuery(''); }}>
          <div className="admin-modal vip-modal" onClick={e => e.stopPropagation()}>
            <div className="vip-modal-header">
              <div>
                <h2>Add Country</h2>
                <p style={{ fontSize: '0.8rem', color: 'var(--admin-text-muted)', marginTop: '0.15rem' }}>
                  {filteredCountries.length} countries available
                </p>
              </div>
              <button
                className="vip-modal-close"
                onClick={() => { setShowModal(false); setSearchQuery(''); }}
              >
                <X size={20} />
              </button>
            </div>

            <div className="vip-modal-search">
              <Search size={16} />
              <input
                type="text"
                placeholder="Search by name or code…"
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="vip-search-input"
                autoFocus
              />
            </div>

            {modalError && (
              <div className="vip-modal-error">{modalError}</div>
            )}

            <div className="vip-country-list">
              {filteredCountries.length === 0 ? (
                <div className="vip-no-results">
                  {searchQuery ? 'No countries match your search.' : 'All countries have been added.'}
                </div>
              ) : (
                filteredCountries.map(country => (
                  <button
                    key={country.code}
                    className="vip-country-option"
                    onClick={() => addCountry(country.code)}
                    disabled={adding}
                  >
                    <span className="vip-country-option-flag">{country.flag}</span>
                    <span className="vip-country-option-name">{country.name}</span>
                    <span className="vip-country-option-code">{country.code}</span>
                  </button>
                ))
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
