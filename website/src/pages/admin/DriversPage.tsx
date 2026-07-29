import { useEffect, useState, useMemo } from 'react';
import { Search, Download } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface DriverRow {
  id: string;
  first_name: string | null;
  last_name: string | null;
  email: string;
  driver_details: { status: string; is_online: boolean; rating: number; rating_count: number } | null;
  vehicle: { make: string; model: string; year: number; color: string; license_plate: string } | null;
  completed_rides: number;
}

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
        .select('id, email, first_name, last_name, driver_details ( status, is_online, rating, rating_count )')
        .eq('role', 'chauffeur')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (profileError) throw profileError;

      const ids = profiles?.map((p) => p.id) || [];

      const [vehicleRes, rideRes] = await Promise.all([
        supabase
          .from('vehicles')
          .select('driver_id, make, model, year, color, license_plate')
          .in('driver_id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']),
        supabase
          .from('rides')
          .select('driver_id')
          .eq('status', 'completed')
          .in('driver_id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']),
      ]);

      if (vehicleRes.error) throw vehicleRes.error;
      if (rideRes.error) throw rideRes.error;

      const vehicleMap = new Map<string, typeof vehicleRes.data[0]>();
      vehicleRes.data?.forEach((v) => vehicleMap.set(v.driver_id, v));

      const rideCountMap = new Map<string, number>();
      rideRes.data?.forEach((r) => {
        rideCountMap.set(r.driver_id, (rideCountMap.get(r.driver_id) || 0) + 1);
      });

      setDrivers(
        (profiles || []).map((p) => ({
          id: p.id,
          first_name: p.first_name,
          last_name: p.last_name,
          email: p.email,
          driver_details: p.driver_details as unknown as DriverRow['driver_details'],
          vehicle: vehicleMap.get(p.id) || null,
          completed_rides: rideCountMap.get(p.id) || 0,
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
      const rating = d.driver_details?.rating != null ? d.driver_details.rating.toFixed(1) : '--';
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
    const details = d.driver_details;
    if (!details) return <span className="admin-badge admin-badge-warning">Pending Auth</span>;
    if (details.is_online && details.status === 'approved') return <span className="admin-badge admin-badge-success">Online</span>;
    if (details.status === 'approved') return <span className="admin-badge admin-badge-info">En Route</span>;
    return <span className="admin-badge admin-badge-warning">Pending Auth</span>;
  };

  const statusLabel = (d: DriverRow) => {
    const details = d.driver_details;
    if (!details) return 'Pending Auth';
    if (details.is_online && details.status === 'approved') return 'Online';
    if (details.status === 'approved') return 'En Route';
    return 'Pending Auth';
  };

  const fullName = (d: DriverRow) => [d.first_name, d.last_name].filter(Boolean).join(' ') || d.email;

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Chauffeur Operations</h1>
          <p>Manage chauffeur profiles, approvals, and statuses</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="admin-btn" onClick={exportCSV}>
            <Download size={16} />
            Export CSV
          </button>
        </div>
      </div>

      <div className="admin-table-wrapper">
        <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', gap: '1rem' }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input
              type="text"
              placeholder="Search chauffeurs..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
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
                <th scope="col">Vehicle</th>
                <th scope="col">Rating</th>
                <th scope="col">Completed Rides</th>
                <th scope="col">Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No chauffeurs match your search.' : 'No chauffeurs found.'}
                  </td>
                </tr>
              ) : (
                filtered.map((d) => (
                  <tr key={d.id}>
                    <td><div style={{ fontWeight: 500 }}>{fullName(d)}</div></td>
                    <td>
                      {d.vehicle
                        ? `${d.vehicle.make} ${d.vehicle.model} (${d.vehicle.license_plate})`
                        : '--'}
                    </td>
                    <td>{d.driver_details?.rating != null ? `⭐ ${d.driver_details.rating.toFixed(1)}` : '--'}</td>
                    <td>{d.completed_rides}</td>
                    <td>{statusBadge(d)}</td>
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
