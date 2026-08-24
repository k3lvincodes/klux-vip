import { useEffect, useState, useMemo } from 'react';
import { Search, Download } from 'lucide-react';
import { supabase } from '../../lib/supabase';

type ChauffeurStatus = 'online' | 'on_ride' | 'offline' | 'pending' | 'suspended' | 'dormant';

interface DriverRow {
  id: string;
  first_name: string | null;
  last_name: string | null;
  email: string;
  last_seen_at: string | null;
  driver_details: { status: string; is_online: boolean; rating: number; rating_count: number } | null;
  vehicle: { make: string; model: string; year: number; color: string; license_plate: string } | null;
  completed_rides: number;
  has_active_ride: boolean;
}

function computeChauffeurStatus(d: DriverRow): ChauffeurStatus {
  const details = d.driver_details;
  if (!details) return 'pending';
  if (details.status === 'suspended') return 'suspended';
  if (details.status !== 'approved') return 'pending';
  if (!d.last_seen_at) return 'dormant';
  const diff = Date.now() - new Date(d.last_seen_at).getTime();
  const seconds = diff / 1000;
  if (d.has_active_ride) return 'on_ride';
  if (seconds <= 30) return 'online';
  const days = seconds / 86400;
  if (days > 180) return 'dormant';
  return 'offline';
}

const chauffeurStatusConfig: Record<ChauffeurStatus, { label: string; className: string }> = {
  online: { label: 'Online', className: 'admin-badge-success' },
  on_ride: { label: 'On Ride', className: 'admin-badge-info' },
  offline: { label: 'Offline', className: 'admin-badge-warning' },
  pending: { label: 'Pending', className: 'admin-badge-warning' },
  suspended: { label: 'Suspended', className: 'admin-badge-danger' },
  dormant: { label: 'Dormant', className: 'admin-badge-danger' },
};

export default function DriversPage() {
  const [drivers, setDrivers] = useState<DriverRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchDrivers();
  }, []);

  const fetchDrivers = async () => {
    try {
      const { data: profiles, error: profileError } = await supabase
        .from('profiles')
        .select('id, email, first_name, last_name, last_seen_at, driver_details ( status, is_online, rating, rating_count )')
        .eq('role', 'chauffeur')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (profileError) throw profileError;

      const ids = profiles?.map((p) => p.id) || [];

      const [vehicleRes, rideRes, activeRideRes] = await Promise.all([
        supabase
          .from('vehicles')
          .select('driver_id, make, model, year, color, license_plate')
          .in('driver_id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']),
        supabase
          .from('rides')
          .select('driver_id')
          .eq('status', 'completed')
          .in('driver_id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']),
        supabase
          .from('rides')
          .select('driver_id')
          .in('status', ['accepted', 'arriving', 'in_progress'])
          .in('driver_id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']),
      ]);

      if (vehicleRes.error) throw vehicleRes.error;
      if (rideRes.error) throw rideRes.error;
      if (activeRideRes.error) throw activeRideRes.error;

      const vehicleMap = new Map<string, typeof vehicleRes.data[0]>();
      vehicleRes.data?.forEach((v) => vehicleMap.set(v.driver_id, v));

      const rideCountMap = new Map<string, number>();
      rideRes.data?.forEach((r) => {
        rideCountMap.set(r.driver_id, (rideCountMap.get(r.driver_id) || 0) + 1);
      });

      const activeRideSet = new Set<string>();
      activeRideRes.data?.forEach((r) => activeRideSet.add(r.driver_id));

      setDrivers(
        (profiles || []).map((p) => ({
          id: p.id,
          first_name: p.first_name,
          last_name: p.last_name,
          email: p.email,
          last_seen_at: p.last_seen_at as string | null ?? null,
          driver_details: p.driver_details as unknown as DriverRow['driver_details'],
          vehicle: vehicleMap.get(p.id) || null,
          completed_rides: rideCountMap.get(p.id) || 0,
          has_active_ride: activeRideSet.has(p.id),
        }))
      );
    } catch (err) {
      setError('Failed to load drivers');
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    if (!search.trim()) return drivers;
    const q = search.toLowerCase();
    return drivers.filter((d) => {
      const name = [d.first_name, d.last_name].filter(Boolean).join(' ').toLowerCase();
      const plate = d.vehicle?.license_plate?.toLowerCase() || '';
      return name.includes(q) || d.email.toLowerCase().includes(q) || plate.includes(q);
    });
  }, [drivers, search]);

  const exportCSV = () => {
    const headers = ['Chauffeur', 'Email', 'Vehicle', 'Rating', 'Completed Rides', 'Status'];
    const rows = filtered.map((d) => {
      const name = [d.first_name, d.last_name].filter(Boolean).join(' ') || d.email;
      const vehicle = d.vehicle
        ? `${d.vehicle.make} ${d.vehicle.model} (${d.vehicle.license_plate})`
        : '--';
      const rating = d.driver_details?.rating != null ? d.driver_details.rating.toFixed(1) : '0.0';
      const status = statusLabel(d);
      return [name, d.email, vehicle, rating, d.completed_rides, status];
    });
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `drivers_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const statusBadge = (d: DriverRow) => {
    const s = computeChauffeurStatus(d);
    return <span className={`admin-badge ${chauffeurStatusConfig[s].className}`}>{chauffeurStatusConfig[s].label}</span>;
  };

  const statusLabel = (d: DriverRow) => {
    const s = computeChauffeurStatus(d);
    return chauffeurStatusConfig[s].label;
  };

  const fullName = (d: DriverRow) => [d.first_name, d.last_name].filter(Boolean).join(' ') || d.email;

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Chauffeur Operations</h1>
          <p>Manage chauffeur profiles, approvals, and statuses</p>
        </div>
        <div className="admin-page-header-actions">
          <button className="admin-btn" onClick={exportCSV}>
            <Download size={16} />
            Export CSV
          </button>
        </div>
      </div>

      <div className="admin-table-wrapper">
        <div className="admin-table-filter-bar">
          <div className="admin-search-wrapper">
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input
              type="text"
              placeholder="Search chauffeurs..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="admin-search-input"
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>Loading chauffeurs...</div>
        ) : error ? (
          <div style={{ padding: '3rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error}</p>
            <button className="admin-btn" onClick={() => { setError(null); setLoading(true); fetchDrivers(); }}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Chauffeur</th>
                <th scope="col">Email</th>
                <th scope="col">Vehicle</th>
                <th scope="col">Rating</th>
                <th scope="col">Completed Rides</th>
                <th scope="col">Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No chauffeurs match your search.' : 'No chauffeurs found.'}
                  </td>
                </tr>
              ) : (
                filtered.map((d) => (
                  <tr key={d.id}>
                    <td data-label="Chauffeur"><div style={{ fontWeight: 500 }}>{fullName(d)}</div></td>
                    <td data-label="Email">{d.email}</td>
                    <td data-label="Vehicle">
                      {d.vehicle
                        ? `${d.vehicle.make} ${d.vehicle.model} (${d.vehicle.license_plate})`
                        : '--'}
                    </td>
                    <td data-label="Rating">⭐ {d.driver_details?.rating != null ? d.driver_details.rating.toFixed(1) : '0.0'}</td>
                    <td data-label="Completed Rides">{d.completed_rides}</td>
                    <td data-label="Status">{statusBadge(d)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
