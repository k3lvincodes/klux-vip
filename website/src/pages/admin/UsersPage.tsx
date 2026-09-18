import { useEffect, useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Search, 
  Download, 
  Users, 
  CheckCircle2, 
  UserCheck, 
  RotateCw,
  X,
  Eye,
  Car
} from 'lucide-react';

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
  online: { label: 'Online Now', className: 'admin-badge-success' },
  active: { label: 'Active Member', className: 'admin-badge-success' },
  inactive: { label: 'Inactive', className: 'admin-badge-info' },
  dormant: { label: 'Dormant', className: 'admin-badge-danger' },
  unverified: { label: 'Unverified Email', className: 'admin-badge-warning' },
};

type ClientFilterTab = 'all' | 'online' | 'active' | 'inactive' | 'unverified';

export default function UsersPage() {
  const navigate = useNavigate();
  const [passengers, setPassengers] = useState<Passenger[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState<ClientFilterTab>('all');

  useEffect(() => {
    fetchPassengers();
  }, []);

  const fetchPassengers = async () => {
    try {
      setLoading(true);
      setError(null);
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
          last_seen_at: ((p as Record<string, unknown>).last_seen_at as string | null) ?? null,
          email_verified_at: ((p as Record<string, unknown>).email_verified_at as string | null) ?? null,
        }))
      );
    } catch (err) {
      setError('Failed to load client registry');
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    return passengers.filter((p) => {
      const s = computeStatus({ email_verified_at: p.email_verified_at, last_seen_at: p.last_seen_at });
      // Tab filter
      if (activeTab === 'online' && s !== 'online') return false;
      if (activeTab === 'active' && s !== 'active') return false;
      if (activeTab === 'inactive' && s !== 'inactive' && s !== 'dormant') return false;
      if (activeTab === 'unverified' && s !== 'unverified') return false;

      // Text search
      if (!search.trim()) return true;
      const q = search.toLowerCase();
      const name = [p.first_name, p.last_name].filter(Boolean).join(' ').toLowerCase();
      return name.includes(q) || p.email.toLowerCase().includes(q) || p.id.toLowerCase().includes(q);
    });
  }, [passengers, activeTab, search]);

  const tabCounts = useMemo(() => {
    return {
      all: passengers.length,
      online: passengers.filter(p => computeStatus(p) === 'online').length,
      active: passengers.filter(p => computeStatus(p) === 'active').length,
      inactive: passengers.filter(p => ['inactive', 'dormant'].includes(computeStatus(p))).length,
      unverified: passengers.filter(p => computeStatus(p) === 'unverified').length,
    };
  }, [passengers]);

  const totalCompletedTrips = useMemo(() => {
    return passengers.reduce((sum, p) => sum + p.total_rides, 0);
  }, [passengers]);

  const exportCSV = () => {
    const headers = ['Client ID', 'Full Name', 'Email', 'Registration Date', 'Total Trips', 'Status'];
    const rows = filtered.map((p) => {
      const name = [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email;
      const joined = new Date(p.created_at).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      });
      const status = computeStatus({ email_verified_at: p.email_verified_at, last_seen_at: p.last_seen_at });
      return [p.id.slice(0, 8), name, p.email, joined, p.total_rides, statusConfig[status].label];
    });

    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `clients_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const fullName = (p: Passenger) =>
    [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email;

  const shortId = (id: string) => id.slice(0, 8);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Page Header */}
      <div className="admin-page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1>Client Registry</h1>
          <p>Passenger accounts, membership activity, verification standing, and trip volume</p>
        </div>
        <div className="admin-page-header-actions">
          <button className="admin-btn admin-btn-outline" onClick={fetchPassengers} title="Refresh registry">
            <RotateCw size={14} /> Refresh
          </button>
          <button className="admin-btn" onClick={exportCSV}>
            <Download size={14} /> Export CSV
          </button>
        </div>
      </div>

      {/* Summary KPI Cards */}
      <div className="admin-kpi-summary-grid">
        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Registered Clients</span>
            <div className="admin-kpi-value">{tabCounts.all}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(255, 255, 255, 0.03)', color: '#fff' }}>
            <Users size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Active Members</span>
            <div className="admin-kpi-value">{tabCounts.active}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(16, 185, 129, 0.08)', color: 'var(--admin-success)', borderColor: 'rgba(16, 185, 129, 0.2)' }}>
            <UserCheck size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Online Standby</span>
            <div className="admin-kpi-value">{tabCounts.online}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(59, 130, 246, 0.08)', color: 'var(--admin-info)', borderColor: 'rgba(59, 130, 246, 0.2)' }}>
            <CheckCircle2 size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Total Completed Trips</span>
            <div className="admin-kpi-value">{totalCompletedTrips}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(244, 197, 34, 0.08)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
            <Car size={18} />
          </div>
        </div>
      </div>

      {/* Main Table Card */}
      <div className="admin-table-wrapper">
        
        {/* Filter Bar & Tabs */}
        <div className="admin-table-filter-bar" style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem', alignItems: 'stretch' }}>
          
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
            
            {/* Status Filter Tabs */}
            <div className="admin-filter-tabs">
              <button 
                className={`admin-filter-tab ${activeTab === 'all' ? 'active' : ''}`}
                onClick={() => setActiveTab('all')}
              >
                All Clients <span className="admin-filter-count">{tabCounts.all}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'online' ? 'active' : ''}`}
                onClick={() => setActiveTab('online')}
              >
                Online Now <span className="admin-filter-count">{tabCounts.online}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'active' ? 'active' : ''}`}
                onClick={() => setActiveTab('active')}
              >
                Active <span className="admin-filter-count">{tabCounts.active}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'inactive' ? 'active' : ''}`}
                onClick={() => setActiveTab('inactive')}
              >
                Inactive <span className="admin-filter-count">{tabCounts.inactive}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'unverified' ? 'active' : ''}`}
                onClick={() => setActiveTab('unverified')}
              >
                Unverified <span className="admin-filter-count">{tabCounts.unverified}</span>
              </button>
            </div>

            {/* Search Box */}
            <div className="admin-search-wrapper" style={{ minWidth: 260 }}>
              <Search size={15} style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)', color: '#71717a' }} />
              <input
                type="text"
                placeholder="Search name, email, client ID..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="admin-search-input"
                style={{ paddingLeft: '2.4rem' }}
              />
              {search && (
                <button 
                  onClick={() => setSearch('')}
                  style={{ position: 'absolute', right: '0.75rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: '#71717a', cursor: 'pointer' }}
                >
                  <X size={14} />
                </button>
              )}
            </div>

          </div>
        </div>

        {/* Table Content */}
        {loading ? (
          <div style={{ padding: '3.5rem', textAlign: 'center', color: '#a1a1aa' }}>
            <RotateCw size={24} className="admin-spin" style={{ margin: '0 auto 0.75rem', display: 'block', color: 'var(--admin-primary)' }} />
            Loading client accounts...
          </div>
        ) : error ? (
          <div style={{ padding: '3.5rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem', fontSize: '0.9rem' }}>{error}</p>
            <button className="admin-btn" onClick={fetchPassengers}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Client Profile</th>
                <th scope="col">Email Address</th>
                <th scope="col" style={{ width: '130px' }}>Member Since</th>
                <th scope="col" style={{ width: '120px' }}>Trips Logged</th>
                <th scope="col" style={{ width: '140px' }}>Status</th>
                <th scope="col" style={{ width: '60px', textAlign: 'right' }}></th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '3.5rem 1rem', color: '#71717a' }}>
                    {search ? 'No client accounts match your search query.' : 'No client records found in this view.'}
                  </td>
                </tr>
              ) : (
                filtered.map((p) => {
                  const s = computeStatus({ email_verified_at: p.email_verified_at, last_seen_at: p.last_seen_at });
                  return (
                    <tr key={p.id} style={{ cursor: 'pointer' }} onClick={() => navigate(`/admin/users/${p.id}`)}>
                      <td data-label="Client Profile">
                        <div className="admin-table-user-cell">
                          <div className="admin-avatar-small">
                            {fullName(p).charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <div style={{ fontWeight: 600, color: '#fff', fontSize: '0.85rem' }}>{fullName(p)}</div>
                            <div style={{ fontSize: '0.68rem', color: '#71717a', fontFamily: 'monospace' }}>#{shortId(p.id)}</div>
                          </div>
                        </div>
                      </td>
                      <td data-label="Email Address">
                        <span style={{ fontSize: '0.84rem', color: '#e4e4e7' }}>{p.email}</span>
                      </td>
                      <td data-label="Member Since">
                        <span style={{ fontSize: '0.82rem', color: '#a1a1aa' }}>
                          {new Date(p.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                        </span>
                      </td>
                      <td data-label="Trips Logged">
                        <span style={{ fontWeight: 600, color: '#fff', fontSize: '0.88rem', fontVariantNumeric: 'tabular-nums' }}>
                          {p.total_rides}
                        </span>
                      </td>
                      <td data-label="Status">
                        <span className={`admin-badge ${statusConfig[s].className}`}>
                          {statusConfig[s].label}
                        </span>
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <button 
                          className="admin-icon-btn" 
                          style={{ width: 28, height: 28 }}
                          onClick={(e) => { e.stopPropagation(); navigate(`/admin/users/${p.id}`); }}
                          title="View full client dossier & ride history"
                        >
                          <Eye size={13} />
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        )}

      </div>
    </div>
  );
}
