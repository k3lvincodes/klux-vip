import { useState, useEffect, useMemo } from 'react';
import { supabase } from '../../lib/supabase';
import { Search, ChevronDown, Plus, X } from 'lucide-react';

interface CountryState {
  name: string;
  vipAmount: number;
  inherited: boolean;
}

interface SelectedCountry {
  code: string;
  name: string;
  flag: string;
  vipAmount: number;
  states: CountryState[];
  expanded: boolean;
}

interface FareRate {
  id: string;
  country_code: string;
  state_or_region: string | null;
  vip_amount: number | null;
}

const COUNTRIES: { code: string; name: string; flag: string; states: string[] }[] = [
  { code: 'US', name: 'United States', flag: '🇺🇸', states: ['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'] },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧', states: ['England', 'Scotland', 'Wales', 'Northern Ireland'] },
  { code: 'CA', name: 'Canada', flag: '🇨🇦', states: ['Alberta', 'British Columbia', 'Manitoba', 'New Brunswick', 'Newfoundland and Labrador', 'Nova Scotia', 'Ontario', 'Prince Edward Island', 'Quebec', 'Saskatchewan', 'Northwest Territories', 'Nunavut', 'Yukon'] },
  { code: 'AU', name: 'Australia', flag: '🇦🇺', states: ['New South Wales', 'Victoria', 'Queensland', 'Western Australia', 'South Australia', 'Tasmania', 'Australian Capital Territory', 'Northern Territory'] },
  { code: 'NG', name: 'Nigeria', flag: '🇳🇬', states: ['Lagos', 'Abuja FCT', 'Rivers', 'Kano', 'Oyo', 'Kaduna', 'Delta', 'Edo', 'Ogun', 'Anambra', 'Akwa Ibom', 'Enugu', 'Benue', 'Kwara', 'Imo', 'Abia', 'Nasarawa', 'Plateau', 'Borno', 'Bauchi', 'Osun', 'Sokoto', 'Katsina', 'Zamfara', 'Cross River', 'Ondo', 'Ekiti', 'Kogi', 'Ebonyi', 'Gombe', 'Taraba', 'Adamawa', 'Yobe', 'Jigawa', 'Kebbi', 'Niger', 'Bayelsa'] },
  { code: 'BR', name: 'Brazil', flag: '🇧🇷', states: ['São Paulo', 'Rio de Janeiro', 'Minas Gerais', 'Bahia', 'Rio Grande do Sul', 'Paraná', 'Pernambuco', 'Ceará', 'Pará', 'Maranhão', 'Santa Catarina', 'Goiás', 'Amazonas', 'Espírito Santo', 'Rio Grande do Norte', 'Alagoas', 'Mato Grosso', 'Mato Grosso do Sul', 'Distrito Federal', 'Paraíba', 'Piauí', 'Sergipe', 'Rondônia', 'Tocantins', 'Amapá', 'Roraima', 'Acre'] },
  { code: 'DE', name: 'Germany', flag: '🇩🇪', states: ['Bavaria', 'North Rhine-Westphalia', 'Baden-Württemberg', 'Lower Saxony', 'Hesse', 'Berlin', 'Schleswig-Holstein', 'Brandenburg', 'Saxony', 'Rhineland-Palatinate', 'Thuringia', 'Hamburg', 'Saxony-Anhalt', 'Mecklenburg-Vorpommern', 'Saarland', 'Bremen'] },
  { code: 'FR', name: 'France', flag: '🇫🇷', states: ['Île-de-France', 'Auvergne-Rhône-Alpes', 'Nouvelle-Aquitaine', 'Occitanie', 'Hauts-de-France', 'Provence-Alpes-Côte d\'Azur', 'Bretagne', 'Normandie', 'Pays de la Loire', 'Grand Est', 'Bourgogne-Franche-Comté', 'Centre-Val de Loire', 'Corse'] },
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
  { code: 'CL', name: 'Chile', flag: '🇨🇱', states: ['Santiago', 'Valparaíso', 'Biobío', 'Los Lagos', 'Araucanía', 'Coquimbo', 'Antofagasta', 'Maule', 'O\'Higgins', 'Los Ríos', 'Arica y Parinacota', 'Tarapacá', 'Atacama', 'Magallanes', 'Ñuble'] },
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
  { code: 'JO', name: 'Jordan', flag: '🇯🇴', states: ['Amman', 'Zarqa', 'Irbid', 'Balqa', 'Aqaba', 'Madaba', 'Mafraq', 'Karak', 'Tafilah', 'Ma\'an', 'Jerash', 'Ajloun'] },
  { code: 'MA', name: 'Morocco', flag: '🇲🇦', states: ['Casablanca-Settat', 'Rabat-Salé-Kénitra', 'Marrakech-Safi', 'Fès-Meknès', 'Tangier-Tetouan-Al Hoceima', 'Souss-Massa', 'Oriental', 'Drâa-Tafilalet', 'Béni Mellal-Khénifra', 'Guelmim-Oued Noun', 'Laâyoune-Sakia El Hamra', 'Dakhla-Oued Ed-Dahab'] },
  { code: 'DZ', name: 'Algeria', flag: '🇩🇿', states: ['Algiers', 'Oran', 'Constantine', 'Annaba', 'Blida', 'Sétif', 'Tlemcen', 'Béjaïa', 'Batna', 'Sidi Bel Abbès', 'Biskra', 'Tizi Ouzou', 'Chlef', 'Boumerdès', 'Médéa', 'Ouargla', 'Mostaganem', 'Skikda', 'Mascara', 'El Oued'] },
  { code: 'TZ', name: 'Tanzania', flag: '🇹🇿', states: ['Dar es Salaam', 'Mwanza', 'Arusha', 'Mbeya', 'Zanzibar', 'Tanga', 'Morogoro', 'Kilimanjaro', 'Iringa', 'Dodoma', 'Mtwara', 'Kigoma', 'Tabora', 'Shinyanga', 'Rukwa', 'Songwe'] },
  { code: 'UG', name: 'Uganda', flag: '🇺🇬', states: ['Kampala', 'Wakiso', 'Mukono', 'Mbale', 'Mbarara', 'Gulu', 'Jinja', 'Lira', 'Masaka', 'Kasese', 'Hoima', 'Arua', 'Busia', 'Soroti', 'Kabarole'] },
  { code: 'ET', name: 'Ethiopia', flag: '🇪🇹', states: ['Addis Ababa', 'Oromia', 'Amhara', 'Southern Nations', 'Tigray', 'Sidama', 'Afar', 'Somali', 'Benishangul-Gumuz', 'Gambela', 'Harari'] },
  { code: 'CM', name: 'Cameroon', flag: '🇨🇲', states: ['Yaoundé', 'Douala', 'Garoua', 'Bamenda', 'Maroua', 'Bafoussam', 'Nkongsamba', 'Kribi', 'Limbe', 'Ebolowa'] },
  { code: 'CI', name: 'Côte d\'Ivoire', flag: '🇨🇮', states: ['Abidjan', 'Yamoussoukro', 'Bouaké', 'Daloa', 'San-Pédro', 'Korhogo', 'Man', 'Gagnoa', 'Divo', 'Anyama'] },
  { code: 'SN', name: 'Senegal', flag: '🇸🇳', states: ['Dakar', 'Thiès', 'Diourbel', 'Saint-Louis', 'Kaolack', 'Ziguinchor', 'Louga', 'Fatick', 'Kolda', 'Kédougou', 'Kaffrine', 'Matam', 'Sédhiou', 'Tambacounda'] },
  { code: 'PK', name: 'Pakistan', flag: '🇵🇰', states: ['Sindh', 'Punjab', 'Khyber Pakhtunkhwa', 'Balochistan', 'Islamabad', 'Azad Kashmir', 'Gilgit-Baltistan'] },
  { code: 'BD', name: 'Bangladesh', flag: '🇧🇩', states: ['Dhaka', 'Chittagong', 'Khulna', 'Rajshahi', 'Sylhet', 'Barisal', 'Rangpur', 'Mymensingh'] },
  { code: 'LK', name: 'Sri Lanka', flag: '🇱🇰', states: ['Western Province', 'Central Province', 'Southern Province', 'Northern Province', 'Eastern Province', 'North Western Province', 'North Central Province', 'Uva Province', 'Sabaragamuwa Province'] },
  { code: 'NZ', name: 'New Zealand', flag: '🇳🇿', states: ['Auckland', 'Wellington', 'Canterbury', 'Waikato', 'Bay of Plenty', 'Otago', 'Manawatu-Whanganui', 'Hawke\'s Bay', 'Taranaki', 'Southland', 'Northland', 'Tasman', 'Marlborough', 'West Coast', 'Nelson', 'Gisborne'] },
  { code: 'PE', name: 'Peru', flag: '🇵🇪', states: ['Lima', 'Arequipa', 'Cusco', 'La Libertad', 'Lambayeque', 'Piura', 'Junín', 'Cajamarca', 'San Martín', 'Puno', 'Ica', 'Ancash', 'Callao', 'Loreto', 'Tacna', 'Ucayali', 'Huánuco', 'Ayacucho', 'Apurímac', 'Amazonas', 'Huancavelica', 'Moquegua', 'Pasco', 'Tumbes', 'Madre de Dios'] },
  { code: 'UA', name: 'Ukraine', flag: '🇺🇦', states: ['Kyiv', 'Kharkiv', 'Dnipro', 'Odesa', 'Lviv', 'Mykolaiv', 'Zaporizhzhia', 'Vinnytsia', 'Poltava', 'Chernihiv', 'Sumy', 'Zhytomyr', 'Cherkasy', 'Rivne', 'Ivano-Frankivsk', 'Khmelnytskyi', 'Ternopil', 'Volyn', 'Kirovohrad', 'Chernivtsi', 'Zakarpattia'] },
  { code: 'KZ', name: 'Kazakhstan', flag: '🇰🇿', states: ['Almaty', 'Astana', 'Shymkent', 'Karaganda', 'Aktobe', 'Pavlodar', 'East Kazakhstan', 'Atyrau', 'Kostanay', 'West Kazakhstan', 'Kyzylorda', 'Mangystau', 'Turkistan', 'North Kazakhstan', 'Abai', 'Zhetysu', 'Ulytau'] },
];

const SELECTED_COUNTRY_CODES = ['US', 'GB', 'CA', 'AU', 'NG', 'BR'];

export default function PricingPage() {
  const [selectedCountries, setSelectedCountries] = useState<SelectedCountry[]>([]);
  const [showModal, setShowModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadCountries();
  }, []);

  async function loadCountries() {
    setLoading(true);
    const { data } = await supabase.from('fare_rates').select('*').order('country_code');
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

    for (const code of [...SELECTED_COUNTRY_CODES, ...grouped.keys()]) {
      if (processed.has(code)) continue;
      const info = countryMap.get(code);
      if (!info) continue;
      processed.add(code);

      const existing = grouped.get(code);
      const countryDefault = existing?.find(r => !r.state_or_region);
      const stateRates = existing?.filter(r => r.state_or_region) || [];

      result.push({
        code,
        name: info.name,
        flag: info.flag,
        vipAmount: countryDefault?.vip_amount ?? 0,
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
    setLoading(false);
  }

  async function addCountry(code: string) {
    const info = COUNTRIES.find(c => c.code === code);
    if (!info) return;
    if (selectedCountries.some(c => c.code === code)) return;

    const newCountry: SelectedCountry = {
      code,
      name: info.name,
      flag: info.flag,
      vipAmount: 0,
      states: info.states.map(s => ({ name: s, vipAmount: 0, inherited: true })),
      expanded: false,
    };

    await supabase.from('fare_rates').insert({
      country_code: code.toLowerCase(),
      state_or_region: null,
      vip_amount: 0,
    });

    setSelectedCountries(prev => [...prev, newCountry]);
    setShowModal(false);
    setSearchQuery('');
  }

  async function removeCountry(code: string) {
    await supabase.from('fare_rates').delete().eq('country_code', code.toLowerCase());
    setSelectedCountries(prev => prev.filter(c => c.code !== code));
  }

  async function updateCountryVip(code: string, amount: number) {
    setSelectedCountries(prev =>
      prev.map(c =>
        c.code === code
          ? { ...c, vipAmount: amount, states: c.states.map(s => s.inherited ? { ...s, vipAmount: amount } : s) }
          : c
      )
    );

    const { data: existing } = await supabase
      .from('fare_rates')
      .select('id')
      .eq('country_code', code.toLowerCase())
      .is('state_or_region', null)
      .maybeSingle();

    if (existing) {
      await supabase.from('fare_rates').update({ vip_amount: amount }).eq('id', existing.id);
    } else {
      await supabase.from('fare_rates').insert({ country_code: code.toLowerCase(), state_or_region: null, vip_amount: amount });
    }
  }

  async function updateStateVip(code: string, stateName: string, amount: number) {
    setSelectedCountries(prev =>
      prev.map(c =>
        c.code === code
          ? {
              ...c,
              states: c.states.map(s =>
                s.name === stateName ? { ...s, vipAmount: amount, inherited: false } : s
              ),
            }
          : c
      )
    );

    const { data: existing } = await supabase
      .from('fare_rates')
      .select('id')
      .eq('country_code', code.toLowerCase())
      .eq('state_or_region', stateName)
      .maybeSingle();

    if (existing) {
      await supabase.from('fare_rates').update({ vip_amount: amount }).eq('id', existing.id);
    } else {
      await supabase.from('fare_rates').insert({
        country_code: code.toLowerCase(),
        state_or_region: stateName,
        vip_amount: amount,
      });
    }
  }

  async function resetStateToInherit(code: string, stateName: string) {
    const country = selectedCountries.find(c => c.code === code);
    if (!country) return;

    setSelectedCountries(prev =>
      prev.map(c =>
        c.code === code
          ? {
              ...c,
              states: c.states.map(s =>
                s.name === stateName ? { ...s, vipAmount: c.vipAmount, inherited: true } : s
              ),
            }
          : c
      )
    );

    await supabase
      .from('fare_rates')
      .delete()
      .eq('country_code', code.toLowerCase())
      .eq('state_or_region', stateName);
  }

  function toggleExpand(code: string) {
    setSelectedCountries(prev =>
      prev.map(c =>
        c.code === code ? { ...c, expanded: !c.expanded } : c
      )
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

  if (loading) {
    return (
      <div>
        <div className="admin-page-header">
          <div>
            <h1>VIP Country Pricing</h1>
            <p>Manage VIP pricing by country and region.</p>
          </div>
        </div>
        <div style={{ textAlign: 'center', padding: '4rem', color: 'var(--admin-text-muted)' }}>
          Loading...
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>VIP Country Pricing</h1>
          <p>Manage VIP pricing by country and region.</p>
        </div>
        <button onClick={() => setShowModal(true)} className="admin-btn">
          <Plus size={16} />
          Add Country
        </button>
      </div>

      {selectedCountries.length === 0 ? (
        <div className="admin-card" style={{ textAlign: 'center', padding: '4rem 2rem' }}>
          <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🌍</div>
          <p style={{ color: 'var(--admin-text-muted)', fontSize: '1rem', margin: 0 }}>
            No countries selected. Click <strong>Add Country</strong> to get started.
          </p>
        </div>
      ) : (
        <div className="vip-country-grid">
          {selectedCountries.map(country => (
            <div key={country.code} className={`vip-country-card ${country.expanded ? 'expanded' : ''}`}>
              <div className="vip-country-header" onClick={() => toggleExpand(country.code)}>
                <div className="vip-country-info">
                  <span className="vip-country-flag">{country.flag}</span>
                  <div>
                    <span className="vip-country-name">{country.name}</span>
                    <span className="vip-country-code">{country.code}</span>
                  </div>
                </div>
                <div className="vip-country-amount" onClick={e => e.stopPropagation()}>
                  <span className="vip-currency">$</span>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={country.vipAmount}
                    onChange={e => updateCountryVip(country.code, parseFloat(e.target.value) || 0)}
                    className="vip-amount-input"
                    onClick={e => e.stopPropagation()}
                  />
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <button
                    className="vip-remove-btn"
                    onClick={e => {
                      e.stopPropagation();
                      removeCountry(country.code);
                    }}
                    title="Remove country"
                  >
                    <X size={14} />
                  </button>
                  <div className={`vip-chevron ${country.expanded ? 'open' : ''}`}>
                    <ChevronDown size={18} />
                  </div>
                </div>
              </div>

              <div className={`vip-accordion-wrapper ${country.expanded ? 'open' : ''}`}>
                <div className="vip-accordion-inner">
                  <div className="vip-states-header">
                    <span>Regions / States</span>
                    <span className="vip-inherit-hint">Inherited amounts update automatically from country default</span>
                  </div>
                  {country.states.map(state => (
                    <div key={state.name} className="vip-state-row">
                      <span className="vip-state-name">{state.name}</span>
                      <div className="vip-state-amount-group">
                        <span className="vip-currency">$</span>
                        <input
                          type="number"
                          step="0.01"
                          min="0"
                          value={state.vipAmount}
                          onChange={e =>
                            updateStateVip(country.code, state.name, parseFloat(e.target.value) || 0)
                          }
                          className={`vip-amount-input ${state.inherited ? 'inherited' : ''}`}
                        />
                        {!state.inherited && (
                          <button
                            className="vip-reset-btn"
                            onClick={() => resetStateToInherit(country.code, state.name)}
                            title="Reset to inherit country default"
                          >
                            ↺
                          </button>
                        )}
                        {state.inherited && (
                          <span className="vip-inherit-badge" title="Inherits from country default">
                            auto
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <div className="admin-modal-overlay" onClick={() => { setShowModal(false); setSearchQuery(''); }}>
          <div className="admin-modal vip-modal" onClick={e => e.stopPropagation()}>
            <div className="vip-modal-header">
              <h2>Select a Country</h2>
              <button
                className="vip-modal-close"
                onClick={() => { setShowModal(false); setSearchQuery(''); }}
              >
                <X size={20} />
              </button>
            </div>

            <div className="vip-modal-search">
              <Search size={18} />
              <input
                type="text"
                placeholder="Search countries..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="vip-search-input"
                autoFocus
              />
            </div>

            <div className="vip-country-list">
              {filteredCountries.length === 0 ? (
                <div className="vip-no-results">
                  {searchQuery ? 'No countries match your search.' : 'All countries have been selected.'}
                </div>
              ) : (
                filteredCountries.map(country => (
                  <button
                    key={country.code}
                    className="vip-country-option"
                    onClick={() => addCountry(country.code)}
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
