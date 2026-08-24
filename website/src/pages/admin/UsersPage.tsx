import { useEffect, useState, useMemo } from 'react';
import { Search, Download } from 'lucide-react';
import { supabase } from '../../lib/supabase';

type UserStatus = 'online' | 'active' | 'inactive' | 'dormant' | 'unverified';

interface Passenger {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  created_at: string;
  total_rides: number;
  last_seen_at: string | null;
  email_verified_at: string | null;
}

function computeStatus(p: Pick<Passenger, 'last_seen_at' | 'email_verified_at'>): UserStatus {
  if (!p.email_verified_at) return 'unverified';
  if (!p.last_seen_at) return 'dormant';
  const diff = Date.now() - new Date(p.last_seen_at).getTime();
  const seconds = diff / 1000;
  if (seconds <= 30) return 'online';
  const days = seconds / 86400;
  if (days <= 21) return 'active';
  if (days <= 90) return 'inactive';
  return 'dormant';
}

const statusConfig: Record<UserStatus, { label: string; className: string }> = {
  online: { label: 'Online', className: 'admin-badge-success' },
  active: { label: 'Active', className: 'admin-badge-success' },
  inactive: { label: 'Inactive', className: 'admin-badge-info' },
  dormant: { label: 'Dormant', className: 'admin-badge-danger' },
  unverified: { label: 'Unverified', className: 'admin-badge-warning' },
};

export default function UsersPage() {
  const [passengers, setPassengers] = useState<Passenger[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchPassengers();
  }, []);

  const fetchPassengers = async () => {
    try {
      const { data: profiles, error } = await supabase
        .from('profiles')
        .select('id, email, first_name, last_name, created_at, last_seen_at, email_verified_at')
        .eq('role', 'client')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const ids = profiles?.map((p) => p.id) || [];
      const { data: rideData, error: rideError } = await supabase
        .from('rides')
        .select('passenger_id, status')
        .in('passenger_id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']);

      if (rideError) throw rideError;

      const rideMap = new Map<string, number>();
      rideData?.forEach((r) => {
        rideMap.set(r.passenger_id, (rideMap.get(r.passenger_id) || 0) + 1);
      });

      setPassengers(
        (profiles || []).map((p) => ({
          ...p,
          total_rides: rideMap.get(p.id) || 0,
          last_seen_at: (p as Record<string, unknown>).last_seen_at as string | null ?? null,
          email_verified_at: (p as Record<string, unknown>).email_verified_at as string | null ?? null,
        }))
      );
    } catch (err) {
      setError('Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    if (!search.trim()) return passengers;
    const q = search.toLowerCase();
    return passengers.filter(
      (p) =>
        (p.first_name?.toLowerCase() || '').includes(q) ||
        (p.last_name?.toLowerCase() || '').includes(q) ||
        p.email.toLowerCase().includes(q)
    );
  }, [passengers, search]);

  const exportCSV = () => {
    const headers = ['Name', 'Email', 'Joined Date', 'Total Rides', 'Status'];
    const rows = filtered.map((p) => {
      const name = [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email;
      const joined = new Date(p.created_at).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      });
      const status = computeStatus({ email_verified_at: p.email_verified_at, last_seen_at: p.last_seen_at });
      return [name, p.email, joined, p.total_rides, statusConfig[status].label];
    });

    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `passengers_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const formatDate = (iso: string) => {
    return new Date(iso).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const fullName = (p: Passenger) =>
    [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email;

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>User Management</h1>
          <p>View and manage all registered clients</p>
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
              placeholder="Search by name or email..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="admin-search-input"
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>Loading users...</div>
        ) : error ? (
          <div style={{ padding: '3rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error}</p>
            <button className="admin-btn" onClick={() => { setError(null); setLoading(true); fetchPassengers(); }}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Name</th>
                <th scope="col">Email</th>
                <th scope="col">Joined Date</th>
                <th scope="col">Total Rides</th>
                <th scope="col">Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No users match your search.' : 'No clients found.'}
                  </td>
                </tr>
              ) : (
                filtered.map((p) => (
                  <tr key={p.id}>
                    <td data-label="Name"><div style={{ fontWeight: 500 }}>{fullName(p)}</div></td>
                    <td data-label="Email">{p.email}</td>
                    <td data-label="Joined Date">{formatDate(p.created_at)}</td>
                    <td data-label="Total Rides">{p.total_rides}</td>
                    <td data-label="Status">
                      {(() => {
                        const s = computeStatus({ email_verified_at: p.email_verified_at, last_seen_at: p.last_seen_at });
                        return <span className={`admin-badge ${statusConfig[s].className}`}>{statusConfig[s].label}</span>;
                      })()}
                    </td>
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
