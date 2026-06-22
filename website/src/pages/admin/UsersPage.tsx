import { useEffect, useState, useMemo } from 'react';
import { Search, Download } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface Passenger {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  created_at: string;
  total_rides: number;
}

export default function UsersPage() {
  const [passengers, setPassengers] = useState<Passenger[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchPassengers();
  }, []);

  const fetchPassengers = async () => {
    try {
      const { data: profiles, error } = await supabase
        .from('profiles')
        .select('id, email, first_name, last_name, created_at')
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
        }))
      );
    } catch (err) {
      console.error('Error fetching passengers:', err);
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
      const status = p.total_rides > 0 ? 'Active' : 'Unverified';
      return [name, p.email, joined, p.total_rides, status];
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
              placeholder="Search by name or email..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>Loading users...</div>
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
                    <td><div style={{ fontWeight: 500 }}>{fullName(p)}</div></td>
                    <td>{p.email}</td>
                    <td>{formatDate(p.created_at)}</td>
                    <td>{p.total_rides}</td>
                    <td>
                      {p.total_rides > 0 ? (
                        <span className="admin-badge admin-badge-success">Active</span>
                      ) : (
                        <span className="admin-badge admin-badge-warning">Unverified</span>
                      )}
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
