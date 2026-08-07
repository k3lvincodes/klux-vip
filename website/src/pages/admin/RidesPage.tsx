import { useEffect, useState, useMemo } from 'react';
import { Search, Download } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface RideRow {
  id: string;
  passenger_id: string;
  driver_id: string | null;
  pickup_address: string;
  dropoff_address: string;
  fare_amount: number;
  status: string;
  created_at: string;
  passenger_name: string;
  driver_name: string | null;
}

export default function RidesPage() {
  const [rides, setRides] = useState<RideRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchRides();
  }, []);

  const fetchRides = async () => {
    try {
      const { data: ridesData, error } = await supabase
        .from('rides')
        .select('id, passenger_id, driver_id, pickup_address, dropoff_address, fare_amount, status, created_at')
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(100);

      if (error) throw error;

      const ids = new Set<string>();
      ridesData?.forEach((r) => {
        ids.add(r.passenger_id);
        if (r.driver_id) ids.add(r.driver_id);
      });

      const profileIds = Array.from(ids);
      const { data: profiles, error: profileError } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .in('id', profileIds.length > 0 ? profileIds : ['00000000-0000-0000-0000-000000000000']);

      if (profileError) throw profileError;

      const profileMap = new Map<string, { first_name: string | null; last_name: string | null; email: string }>();
      profiles?.forEach((p) => profileMap.set(p.id, p));

      setRides(
        (ridesData || []).map((r) => {
          const passenger = profileMap.get(r.passenger_id);
          const driver = r.driver_id ? profileMap.get(r.driver_id) : null;
          return {
            ...r,
            passenger_name: passenger
              ? [passenger.first_name, passenger.last_name].filter(Boolean).join(' ') || passenger.email
              : 'Unknown',
            driver_name: driver
              ? [driver.first_name, driver.last_name].filter(Boolean).join(' ') || driver.email
              : null,
          };
        })
      );
    } catch (err) {
      setError('Failed to load rides');
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    if (!search.trim()) return rides;
    const q = search.toLowerCase();
    return rides.filter(
      (r) =>
        r.id.toLowerCase().includes(q) ||
        r.passenger_name.toLowerCase().includes(q) ||
        (r.driver_name?.toLowerCase() || '').includes(q)
    );
  }, [rides, search]);

  const exportCSV = () => {
    const headers = ['Ride ID', 'Client', 'Chauffeur', 'Pickup', 'Dropoff', 'Fare', 'Status'];
    const rows = filtered.map((r) => [
      r.id.slice(0, 8),
      r.passenger_name,
      r.driver_name || '--',
      r.pickup_address,
      r.dropoff_address,
      `$${Number(r.fare_amount).toFixed(2)}`,
      statusLabel(r.status),
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `rides_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const statusBadge = (status: string) => {
    switch (status) {
      case 'completed':
        return <span className="admin-badge admin-badge-success">Completed</span>;
      case 'in_progress':
        return <span className="admin-badge admin-badge-info">In Progress</span>;
      case 'requested':
        return <span className="admin-badge admin-badge-warning">Looking for Chauffeur</span>;
      case 'accepted':
      case 'arriving':
        return <span className="admin-badge admin-badge-info">Chauffeur Assigned</span>;
      case 'cancelled':
        return <span className="admin-badge admin-badge-danger">Cancelled</span>;
      default:
        return <span className="admin-badge">{status}</span>;
    }
  };

  const statusLabel = (status: string) => {
    switch (status) {
      case 'completed': return 'Completed';
      case 'in_progress': return 'In Progress';
      case 'requested': return 'Looking for Chauffeur';
      case 'accepted': case 'arriving': return 'Chauffeur Assigned';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  };

  const shortId = (id: string) => id.slice(0, 8);

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Ride History & Dispatch</h1>
          <p>Live tracking and historical records of all trips</p>
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
              placeholder="Search by ID or client..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="admin-search-input"
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>Loading rides...</div>
        ) : error ? (
          <div style={{ padding: '3rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error}</p>
            <button className="admin-btn" onClick={() => { setError(null); setLoading(true); fetchRides(); }}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Ride ID</th>
                <th scope="col">Client</th>
                <th scope="col">Chauffeur</th>
                <th scope="col">Fare</th>
                <th scope="col">Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No rides match your search.' : 'No rides found.'}
                  </td>
                </tr>
              ) : (
                filtered.map((r) => (
                  <tr key={r.id}>
                    <td data-label="Ride ID"><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#{shortId(r.id)}</div></td>
                    <td data-label="Client"><div style={{ fontWeight: 500 }}>{r.passenger_name}</div></td>
                    <td data-label="Chauffeur">{r.driver_name || '--'}</td>
                    <td data-label="Fare">${Number(r.fare_amount).toFixed(2)}</td>
                    <td data-label="Status">{statusBadge(r.status)}</td>
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
