import { useEffect, useState, useMemo } from 'react';
import { 
  Search, 
  Download, 
  CheckCircle2, 

  Clock, 
  AlertCircle, 
  User, 
  CarFront, 
  CircleDollarSign,
  X,
  Eye,
  Map as MapIcon,
  RotateCw
} from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { AdminDrawer } from '../../components/ui/AdminDrawer';

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

type FilterTab = 'all' | 'completed' | 'active' | 'requested' | 'cancelled';

export default function RidesPage() {
  const [rides, setRides] = useState<RideRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState<FilterTab>('all');
  const [selectedRide, setSelectedRide] = useState<RideRow | null>(null);

  useEffect(() => {
    fetchRides();
  }, []);

  const fetchRides = async () => {
    try {
      setLoading(true);
      setError(null);

      // Attempt query with fallback if deleted_at column is absent
      let ridesData: any[] | null = null;
      let ridesError: any = null;

      const resWithDeleted = await supabase
        .from('rides')
        .select('id, passenger_id, driver_id, pickup_address, dropoff_address, fare_amount, status, created_at')
        .order('created_at', { ascending: false })
        .limit(150);

      ridesData = resWithDeleted.data;
      ridesError = resWithDeleted.error;

      if (ridesError) throw ridesError;

      const ids = new Set<string>();
      (ridesData || []).forEach((r) => {
        if (r.passenger_id && typeof r.passenger_id === 'string' && r.passenger_id.trim()) {
          ids.add(r.passenger_id.trim());
        }
        if (r.driver_id && typeof r.driver_id === 'string' && r.driver_id.trim()) {
          ids.add(r.driver_id.trim());
        }
      });

      const profileIds = Array.from(ids);
      const profileMap = new Map<string, { first_name: string | null; last_name: string | null; email: string }>();

      if (profileIds.length > 0) {
        try {
          const { data: profiles, error: profileError } = await supabase
            .from('profiles')
            .select('id, first_name, last_name, email')
            .in('id', profileIds);

          if (!profileError && profiles) {
            profiles.forEach((p) => profileMap.set(p.id, p));
          }
        } catch (pErr) {
          console.warn('Could not load profile records for journeys:', pErr);
        }
      }

      setRides(
        (ridesData || []).map((r) => {
          const passenger = profileMap.get(r.passenger_id);
          const driver = r.driver_id ? profileMap.get(r.driver_id) : null;
          return {
            ...r,
            passenger_name: passenger
              ? [passenger.first_name, passenger.last_name].filter(Boolean).join(' ') || passenger.email
              : 'Client Account',
            driver_name: driver
              ? [driver.first_name, driver.last_name].filter(Boolean).join(' ') || driver.email
              : null,
          };
        })
      );
    } catch (err: any) {
      console.error('Error loading journeys:', err);
      setError(err?.message || 'Failed to load journeys');
    } finally {
      setLoading(false);
    }
  };

  // Status Tab Filters
  const filtered = useMemo(() => {
    return rides.filter((r) => {
      // Tab filter
      if (activeTab === 'completed' && r.status !== 'completed') return false;
      if (activeTab === 'active' && !['in_progress', 'arriving', 'accepted'].includes(r.status)) return false;
      if (activeTab === 'requested' && r.status !== 'requested') return false;
      if (activeTab === 'cancelled' && r.status !== 'cancelled') return false;

      // Text search
      if (!search.trim()) return true;
      const q = search.toLowerCase();
      return (
        r.id.toLowerCase().includes(q) ||
        r.passenger_name.toLowerCase().includes(q) ||
        (r.driver_name?.toLowerCase() || '').includes(q) ||
        r.pickup_address.toLowerCase().includes(q) ||
        r.dropoff_address.toLowerCase().includes(q)
      );
    });
  }, [rides, activeTab, search]);

  // Tab counts
  const tabCounts = useMemo(() => {
    return {
      all: rides.length,
      completed: rides.filter(r => r.status === 'completed').length,
      active: rides.filter(r => ['in_progress', 'arriving', 'accepted'].includes(r.status)).length,
      requested: rides.filter(r => r.status === 'requested').length,
      cancelled: rides.filter(r => r.status === 'cancelled').length,
    };
  }, [rides]);

  // Aggregate stats
  const totalRevenue = useMemo(() => {
    return rides
      .filter(r => r.status === 'completed')
      .reduce((sum, r) => sum + (Number(r.fare_amount) || 0), 0);
  }, [rides]);

  const exportCSV = () => {
    const headers = ['Journey ID', 'Client', 'Chauffeur', 'Pickup Address', 'Dropoff Address', 'Fare ($)', 'Status', 'Date'];
    const rows = filtered.map((r) => [
      r.id.slice(0, 8),
      r.passenger_name,
      r.driver_name || '--',
      r.pickup_address,
      r.dropoff_address,
      Number(r.fare_amount).toFixed(2),
      statusLabel(r.status),
      new Date(r.created_at).toLocaleString(),
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `journeys_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const statusBadge = (status: string) => {
    switch (status) {
      case 'completed':
        return <span className="admin-badge admin-badge-success"><CheckCircle2 size={11} style={{ marginRight: 3 }} /> Completed</span>;
      case 'in_progress':
        return <span className="admin-badge admin-badge-info"><Clock size={11} style={{ marginRight: 3 }} /> In Transit</span>;
      case 'requested':
        return <span className="admin-badge admin-badge-warning">Matching Chauffeur</span>;
      case 'accepted':
        return <span className="admin-badge admin-badge-info">Chauffeur Assigned</span>;
      case 'arriving':
        return <span className="admin-badge admin-badge-info">En Route to Pickup</span>;
      case 'cancelled':
        return <span className="admin-badge admin-badge-danger"><AlertCircle size={11} style={{ marginRight: 3 }} /> Cancelled</span>;
      default:
        return <span className="admin-badge">{status}</span>;
    }
  };

  const statusLabel = (status: string) => {
    switch (status) {
      case 'completed': return 'Completed';
      case 'in_progress': return 'In Transit';
      case 'requested': return 'Matching Chauffeur';
      case 'accepted': return 'Chauffeur Assigned';
      case 'arriving': return 'En Route to Pickup';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  };

  const shortId = (id: string) => id.slice(0, 8);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Page Header */}
      <div className="admin-page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1>Journeys & Chauffeur Services</h1>
          <p>Real-time oversight and historical audit of all executive trips</p>
        </div>
        <div className="admin-page-header-actions">
          <button className="admin-btn admin-btn-outline" onClick={fetchRides} title="Refresh records">
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
            <span className="admin-kpi-label">Total Logged Journeys</span>
            <div className="admin-kpi-value">{tabCounts.all}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(255, 255, 255, 0.03)', color: '#fff' }}>
            <MapIcon size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Completed Trips</span>
            <div className="admin-kpi-value">{tabCounts.completed}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(16, 185, 129, 0.08)', color: 'var(--admin-success)', borderColor: 'rgba(16, 185, 129, 0.2)' }}>
            <CheckCircle2 size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Active In Transit</span>
            <div className="admin-kpi-value">{tabCounts.active}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(59, 130, 246, 0.08)', color: 'var(--admin-info)', borderColor: 'rgba(59, 130, 246, 0.2)' }}>
            <CarFront size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Completed Fares Gross</span>
            <div className="admin-kpi-value">${totalRevenue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(244, 197, 34, 0.08)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
            <CircleDollarSign size={18} />
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
                All Journeys <span className="admin-filter-count">{tabCounts.all}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'completed' ? 'active' : ''}`}
                onClick={() => setActiveTab('completed')}
              >
                Completed <span className="admin-filter-count">{tabCounts.completed}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'active' ? 'active' : ''}`}
                onClick={() => setActiveTab('active')}
              >
                In Transit <span className="admin-filter-count">{tabCounts.active}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'requested' ? 'active' : ''}`}
                onClick={() => setActiveTab('requested')}
              >
                Requested <span className="admin-filter-count">{tabCounts.requested}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'cancelled' ? 'active' : ''}`}
                onClick={() => setActiveTab('cancelled')}
              >
                Cancelled <span className="admin-filter-count">{tabCounts.cancelled}</span>
              </button>
            </div>

            {/* Search Box */}
            <div className="admin-search-wrapper" style={{ minWidth: 260 }}>
              <Search size={15} style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)', color: '#71717a' }} />
              <input
                type="text"
                placeholder="Search journey ID, passenger, route..."
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
            Loading journey telemetry...
          </div>
        ) : error ? (
          <div style={{ padding: '3.5rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem', fontSize: '0.9rem' }}>{error}</p>
            <button className="admin-btn" onClick={fetchRides}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col" style={{ width: '120px' }}>Journey ID</th>
                <th scope="col">Client</th>
                <th scope="col">Itinerary Route</th>
                <th scope="col">Chauffeur</th>
                <th scope="col" style={{ width: '110px' }}>Fare</th>
                <th scope="col" style={{ width: '140px' }}>Status</th>
                <th scope="col" style={{ width: '60px', textAlign: 'right' }}></th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '3.5rem 1rem', color: '#71717a' }}>
                    {search ? 'No journeys match your search query.' : 'No journeys found in this view.'}
                  </td>
                </tr>
              ) : (
                filtered.map((r) => (
                  <tr key={r.id} style={{ cursor: 'pointer' }} onClick={() => setSelectedRide(r)}>
                    <td data-label="Journey ID">
                      <div style={{ fontFamily: 'monospace', color: '#a1a1aa', fontSize: '0.82rem' }}>
                        #{shortId(r.id)}
                      </div>
                      <div style={{ fontSize: '0.68rem', color: '#52525b', marginTop: 2 }}>
                        {new Date(r.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}
                      </div>
                    </td>
                    <td data-label="Client">
                      <div className="admin-table-user-cell">
                        <div className="admin-avatar-small">
                          {r.passenger_name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div style={{ fontWeight: 600, color: '#fff', fontSize: '0.85rem' }}>{r.passenger_name}</div>
                          <div style={{ fontSize: '0.7rem', color: '#71717a' }}>Passenger</div>
                        </div>
                      </div>
                    </td>
                    <td data-label="Route">
                      <div className="admin-route-preview">
                        <div className="admin-route-stop" title={r.pickup_address}>
                          <span className="admin-route-dot pickup" />
                          <span style={{ color: '#e4e4e7' }}>{r.pickup_address || 'Pickup Point'}</span>
                        </div>
                        <div className="admin-route-connector" />
                        <div className="admin-route-stop" title={r.dropoff_address}>
                          <span className="admin-route-dot dropoff" />
                          <span style={{ color: '#a1a1aa' }}>{r.dropoff_address || 'Destination'}</span>
                        </div>
                      </div>
                    </td>
                    <td data-label="Chauffeur">
                      {r.driver_name ? (
                        <div className="admin-table-user-cell">
                          <div className="admin-avatar-small" style={{ background: 'rgba(244, 197, 34, 0.1)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
                            <CarFront size={14} />
                          </div>
                          <div>
                            <div style={{ fontWeight: 500, color: '#fff', fontSize: '0.85rem' }}>{r.driver_name}</div>
                            <div style={{ fontSize: '0.7rem', color: '#10b981' }}>Assigned</div>
                          </div>
                        </div>
                      ) : (
                        <span style={{ color: '#71717a', fontSize: '0.82rem', fontStyle: 'italic' }}>Pending Assignment</span>
                      )}
                    </td>
                    <td data-label="Fare">
                      <span style={{ fontWeight: 700, color: '#fff', fontVariantNumeric: 'tabular-nums', fontSize: '0.9rem' }}>
                        ${Number(r.fare_amount).toFixed(2)}
                      </span>
                    </td>
                    <td data-label="Status">
                      {statusBadge(r.status)}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <button 
                        className="admin-icon-btn" 
                        style={{ width: 28, height: 28 }}
                        onClick={(e) => { e.stopPropagation(); setSelectedRide(r); }}
                        title="View details"
                      >
                        <Eye size={13} />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}

      </div>

      {/* Journey Detail Slide-Over Drawer (Zero Modal) */}
      <AdminDrawer
        isOpen={!!selectedRide}
        onClose={() => setSelectedRide(null)}
        width={480}
        title={selectedRide ? `Journey #${shortId(selectedRide.id)}` : ''}
        subtitle={selectedRide ? `Logged on ${new Date(selectedRide.created_at).toLocaleString()}` : ''}
        headerAction={selectedRide ? statusBadge(selectedRide.status) : undefined}
        footer={
          <button className="admin-btn admin-btn-outline" onClick={() => setSelectedRide(null)}>
            Done
          </button>
        }
      >
        {selectedRide && (
          <>
            {/* Route Card */}
            <div style={{ background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '1rem', marginBottom: '0.75rem' }}>
              <span style={{ fontSize: '0.7rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                Itinerary Route
              </span>
              
              <div style={{ marginTop: '0.75rem', display: 'flex', flexDirection: 'column', gap: 10 }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                  <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--admin-success)', marginTop: 4, flexShrink: 0 }} />
                  <div>
                    <div style={{ fontSize: '0.72rem', color: '#71717a' }}>Pickup Location</div>
                    <div style={{ fontSize: '0.85rem', color: '#fff', fontWeight: 500 }}>{selectedRide.pickup_address}</div>
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                  <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--admin-warning)', marginTop: 4, flexShrink: 0 }} />
                  <div>
                    <div style={{ fontSize: '0.72rem', color: '#71717a' }}>Destination Location</div>
                    <div style={{ fontSize: '0.85rem', color: '#fff', fontWeight: 500 }}>{selectedRide.dropoff_address}</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Passenger & Chauffeur Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginBottom: '0.75rem' }}>
              <div style={{ background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '0.85rem' }}>
                <span style={{ fontSize: '0.7rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                  Client Passenger
                </span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: '0.5rem' }}>
                  <div className="admin-avatar-small">
                    <User size={14} />
                  </div>
                  <div style={{ overflow: 'hidden' }}>
                    <div style={{ fontSize: '0.85rem', fontWeight: 600, color: '#fff', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>{selectedRide.passenger_name}</div>
                    <div style={{ fontSize: '0.7rem', color: '#71717a' }}>Passenger Account</div>
                  </div>
                </div>
              </div>

              <div style={{ background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '0.85rem' }}>
                <span style={{ fontSize: '0.7rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                  Assigned Chauffeur
                </span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: '0.5rem' }}>
                  <div className="admin-avatar-small" style={{ background: 'rgba(244, 197, 34, 0.1)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
                    <CarFront size={14} />
                  </div>
                  <div style={{ overflow: 'hidden' }}>
                    <div style={{ fontSize: '0.85rem', fontWeight: 600, color: '#fff', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>{selectedRide.driver_name || 'Unassigned'}</div>
                    <div style={{ fontSize: '0.7rem', color: selectedRide.driver_name ? '#10b981' : '#71717a' }}>
                      {selectedRide.driver_name ? 'Certified Chauffeur' : 'Awaiting Assignment'}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Fare Summary */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.85rem 1rem', background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10 }}>
              <div>
                <span style={{ fontSize: '0.7rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                  Trip Total Fare
                </span>
                <div style={{ fontSize: '0.75rem', color: '#a1a1aa' }}>Billed upon trip completion</div>
              </div>
              <div style={{ fontSize: '1.35rem', fontWeight: 700, color: '#fff', fontVariantNumeric: 'tabular-nums' }}>
                ${Number(selectedRide.fare_amount).toFixed(2)}
              </div>
            </div>
          </>
        )}
      </AdminDrawer>

    </div>
  );
}
