import { useEffect, useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Search, 
  Download, 
  CarFront, 
  CheckCircle2, 
  Clock, 
  Star, 
  UserCheck, 
  UserX,
  X,
  Eye,
  RotateCw,
  FileText
} from 'lucide-react';

import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
import { AdminDrawer } from '../../components/ui/AdminDrawer';
import { InlineConfirmButton } from '../../components/ui/InlineConfirmButton';

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
  online: { label: 'Online Standby', className: 'admin-badge-success' },
  on_ride: { label: 'On Ride', className: 'admin-badge-info' },
  offline: { label: 'Offline', className: 'admin-badge-warning' },
  pending: { label: 'Pending Review', className: 'admin-badge-warning' },
  suspended: { label: 'Suspended', className: 'admin-badge-danger' },
  dormant: { label: 'Dormant', className: 'admin-badge-danger' },
};

type ChauffeurFilterTab = 'all' | 'online' | 'pending' | 'approved' | 'suspended';

export default function DriversPage() {
  const navigate = useNavigate();
  const toast = useToast();
  const [drivers, setDrivers] = useState<DriverRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState<ChauffeurFilterTab>('all');
  const [selectedDriver, setSelectedDriver] = useState<DriverRow | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    fetchDrivers();
  }, []);

  const fetchDrivers = async () => {
    try {
      setLoading(true);
      setError(null);
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
        (profiles || []).map((p) => {
          const raw = p.driver_details as any;
          const details: DriverRow['driver_details'] = Array.isArray(raw)
            ? (raw[0] || null)
            : (raw || null);

          return {
            id: p.id,
            first_name: p.first_name,
            last_name: p.last_name,
            email: p.email,
            last_seen_at: (p.last_seen_at as string | null) ?? null,
            driver_details: details,
            vehicle: vehicleMap.get(p.id) || null,
            completed_rides: rideCountMap.get(p.id) || 0,
            has_active_ride: activeRideSet.has(p.id),
          };
        })
      );
    } catch (err) {
      setError('Failed to load chauffeur roster');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (driverId: string, newStatus: 'approved' | 'suspended') => {
    try {
      setActionLoading(true);

      // 1. Try dedicated admin RPC function first
      let rpcSucceeded = false;
      try {
        const { error: rpcError } = await supabase.rpc('admin_set_driver_status', {
          p_driver_id: driverId,
          p_status: newStatus,
        });
        if (!rpcError) {
          rpcSucceeded = true;
        } else {
          console.warn('RPC admin_set_driver_status error, falling back:', rpcError.message);
        }
      } catch (e) {
        console.warn('RPC admin_set_driver_status not available:', e);
      }

      if (!rpcSucceeded) {
        // 2. Direct update fallback
        const { data: updateData, error: updateError } = await supabase
          .from('driver_details')
          .update({
            status: newStatus,
            verification_status: newStatus === 'approved' ? 'approved' : 'rejected',
            updated_at: new Date().toISOString(),
          })
          .eq('profile_id', driverId)
          .select();

        if (updateError) {
          throw updateError;
        }

        // If no row was updated (driver_details row doesn't exist yet), insert it
        if (!updateData || updateData.length === 0) {
          const { error: insertError } = await supabase
            .from('driver_details')
            .insert({
              profile_id: driverId,
              status: newStatus,
              verification_status: newStatus === 'approved' ? 'approved' : 'rejected',
              is_online: false,
              rating: 5.0,
              rating_count: 0,
              updated_at: new Date().toISOString(),
            });

          if (insertError) throw insertError;
        }

        // Keep profiles table in sync
        await supabase
          .from('profiles')
          .update({
            verification_status: newStatus === 'approved' ? 'approved' : 'rejected',
            updated_at: new Date().toISOString(),
          })
          .eq('id', driverId);
      }

      await fetchDrivers();

      setSelectedDriver((prev) => {
        if (!prev || prev.id !== driverId) return prev;
        const currentDetails = prev.driver_details;
        return {
          ...prev,
          driver_details: currentDetails
            ? { ...currentDetails, status: newStatus }
            : { status: newStatus, is_online: false, rating: 5.0, rating_count: 0 },
        };
      });
      toast.success(newStatus === 'approved' ? 'Chauffeur approved successfully' : 'Chauffeur suspended');
    } catch (err: any) {
      console.error('Failed to update status:', err);
      toast.error(err.message || 'Failed to update chauffeur status');
    } finally {
      setActionLoading(false);
    }
  };

  const filtered = useMemo(() => {
    return drivers.filter((d) => {
      const s = computeChauffeurStatus(d);
      // Tab filter
      if (activeTab === 'online' && s !== 'online') return false;
      if (activeTab === 'pending' && s !== 'pending') return false;
      if (activeTab === 'approved' && d.driver_details?.status !== 'approved') return false;
      if (activeTab === 'suspended' && s !== 'suspended') return false;

      // Text search
      if (!search.trim()) return true;
      const q = search.toLowerCase();
      const name = [d.first_name, d.last_name].filter(Boolean).join(' ').toLowerCase();
      const plate = d.vehicle?.license_plate?.toLowerCase() || '';
      return (
        name.includes(q) || 
        d.email.toLowerCase().includes(q) || 
        plate.includes(q) ||
        (d.vehicle ? `${d.vehicle.make} ${d.vehicle.model}`.toLowerCase().includes(q) : false)
      );
    });
  }, [drivers, activeTab, search]);

  const tabCounts = useMemo(() => {
    return {
      all: drivers.length,
      online: drivers.filter(d => computeChauffeurStatus(d) === 'online').length,
      pending: drivers.filter(d => computeChauffeurStatus(d) === 'pending').length,
      approved: drivers.filter(d => d.driver_details?.status === 'approved').length,
      suspended: drivers.filter(d => computeChauffeurStatus(d) === 'suspended').length,
    };
  }, [drivers]);

  const exportCSV = () => {
    const headers = ['Chauffeur Name', 'Email', 'Vehicle Make & Model', 'License Plate', 'Rating', 'Trips Completed', 'Status'];
    const rows = filtered.map((d) => {
      const name = [d.first_name, d.last_name].filter(Boolean).join(' ') || d.email;
      const vehicleDesc = d.vehicle ? `${d.vehicle.make} ${d.vehicle.model}` : '--';
      const plate = d.vehicle?.license_plate || '--';
      const rating = d.driver_details?.rating != null ? d.driver_details.rating.toFixed(1) : '0.0';
      const status = statusLabel(d);
      return [name, d.email, vehicleDesc, plate, rating, d.completed_rides, status];
    });
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `chauffeurs_${new Date().toISOString().slice(0, 10)}.csv`;
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
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Page Header */}
      <div className="admin-page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1>Chauffeur Operations</h1>
          <p>Roster verification, fleet assignments, performance telemetry, and compliance</p>
        </div>
        <div className="admin-page-header-actions">
          <button className="admin-btn admin-btn-outline" onClick={fetchDrivers} title="Refresh chauffeur roster">
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
            <span className="admin-kpi-label">Total Roster</span>
            <div className="admin-kpi-value">{tabCounts.all}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(255, 255, 255, 0.03)', color: '#fff' }}>
            <CarFront size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Approved Chauffeurs</span>
            <div className="admin-kpi-value">{tabCounts.approved}</div>
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
            <span className="admin-kpi-label">Pending Approval</span>
            <div className="admin-kpi-value">{tabCounts.pending}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(245, 158, 11, 0.08)', color: 'var(--admin-warning)', borderColor: 'rgba(245, 158, 11, 0.2)' }}>
            <Clock size={18} />
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
                All Chauffeurs <span className="admin-filter-count">{tabCounts.all}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'online' ? 'active' : ''}`}
                onClick={() => setActiveTab('online')}
              >
                Online Standby <span className="admin-filter-count">{tabCounts.online}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'approved' ? 'active' : ''}`}
                onClick={() => setActiveTab('approved')}
              >
                Approved <span className="admin-filter-count">{tabCounts.approved}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'pending' ? 'active' : ''}`}
                onClick={() => setActiveTab('pending')}
              >
                Pending Review <span className="admin-filter-count">{tabCounts.pending}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'suspended' ? 'active' : ''}`}
                onClick={() => setActiveTab('suspended')}
              >
                Suspended <span className="admin-filter-count">{tabCounts.suspended}</span>
              </button>
            </div>

            {/* Search Box */}
            <div className="admin-search-wrapper" style={{ minWidth: 260 }}>
              <Search size={15} style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)', color: '#71717a' }} />
              <input
                type="text"
                placeholder="Search name, email, vehicle, plate..."
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
            Loading chauffeur roster...
          </div>
        ) : error ? (
          <div style={{ padding: '3.5rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem', fontSize: '0.9rem' }}>{error}</p>
            <button className="admin-btn" onClick={fetchDrivers}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Chauffeur</th>
                <th scope="col">Assigned Vehicle</th>
                <th scope="col" style={{ width: '120px' }}>Rating</th>
                <th scope="col" style={{ width: '130px' }}>Trips Logged</th>
                <th scope="col" style={{ width: '150px' }}>Status</th>
                <th scope="col" style={{ width: '60px', textAlign: 'right' }}></th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '3.5rem 1rem', color: '#71717a' }}>
                    {search ? 'No chauffeurs match your search query.' : 'No chauffeurs found in this category.'}
                  </td>
                </tr>
              ) : (
                filtered.map((d) => (
                  <tr key={d.id} style={{ cursor: 'pointer' }} onClick={() => setSelectedDriver(d)}>
                    <td data-label="Chauffeur">
                      <div className="admin-table-user-cell">
                        <div className="admin-avatar-small" style={{ background: 'rgba(244, 197, 34, 0.1)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
                          {fullName(d).charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div style={{ fontWeight: 600, color: '#fff', fontSize: '0.85rem' }}>{fullName(d)}</div>
                          <div style={{ fontSize: '0.72rem', color: '#71717a' }}>{d.email}</div>
                        </div>
                      </div>
                    </td>
                    <td data-label="Assigned Vehicle">
                      {d.vehicle ? (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                          <span style={{ fontWeight: 500, color: '#e4e4e7', fontSize: '0.84rem' }}>
                            {d.vehicle.year} {d.vehicle.make} {d.vehicle.model}
                          </span>
                          <div>
                            <span className="admin-plate-badge">{d.vehicle.license_plate}</span>
                          </div>
                        </div>
                      ) : (
                        <span style={{ color: '#71717a', fontSize: '0.82rem', fontStyle: 'italic' }}>No vehicle assigned</span>
                      )}
                    </td>
                    <td data-label="Rating">
                      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: 'rgba(255, 255, 255, 0.03)', border: '1px solid rgba(255, 255, 255, 0.06)', borderRadius: 6, padding: '2px 7px' }}>
                        <Star size={12} fill="#F4C522" color="#F4C522" />
                        <span style={{ fontWeight: 600, color: '#fff', fontSize: '0.8rem', fontVariantNumeric: 'tabular-nums' }}>
                          {d.driver_details?.rating != null ? d.driver_details.rating.toFixed(1) : '0.0'}
                        </span>
                        <span style={{ color: '#71717a', fontSize: '0.7rem' }}>
                          ({d.driver_details?.rating_count || 0})
                        </span>
                      </div>
                    </td>
                    <td data-label="Trips Logged">
                      <span style={{ fontWeight: 600, color: '#fff', fontSize: '0.88rem', fontVariantNumeric: 'tabular-nums' }}>
                        {d.completed_rides}
                      </span>
                    </td>
                    <td data-label="Status">
                      {statusBadge(d)}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: 6 }}>
                        <button 
                          className="admin-icon-btn" 
                          style={{ width: 28, height: 28 }}
                          onClick={(e) => { e.stopPropagation(); navigate(`/admin/documents?driver=${d.id}`); }}
                          title="View chauffeur credentials & documents"
                        >
                          <FileText size={13} />
                        </button>
                        <button 
                          className="admin-icon-btn" 
                          style={{ width: 28, height: 28 }}
                          onClick={(e) => { e.stopPropagation(); setSelectedDriver(d); }}
                          title="View profile"
                        >
                          <Eye size={13} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}

      </div>

      {/* Chauffeur Detail Slide-Over Drawer (Zero Modal) */}
      <AdminDrawer
        isOpen={!!selectedDriver}
        onClose={() => setSelectedDriver(null)}
        width={480}
        title={selectedDriver ? fullName(selectedDriver) : ''}
        subtitle={selectedDriver ? selectedDriver.email : ''}
        headerAction={selectedDriver ? statusBadge(selectedDriver) : undefined}
        footer={
          <button className="admin-btn admin-btn-outline" onClick={() => setSelectedDriver(null)}>
            Done
          </button>
        }
      >
        {selectedDriver && (
          <>
            {/* Performance Stats */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginBottom: '0.5rem' }}>
              <div style={{ background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '0.85rem' }}>
                <span style={{ fontSize: '0.68rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                  Performance Rating
                </span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: '0.4rem' }}>
                  <Star size={16} fill="#F4C522" color="#F4C522" />
                  <span style={{ fontSize: '1.15rem', fontWeight: 700, color: '#fff', fontVariantNumeric: 'tabular-nums' }}>
                    {selectedDriver.driver_details?.rating != null ? selectedDriver.driver_details.rating.toFixed(1) : '0.0'}
                  </span>
                  <span style={{ fontSize: '0.75rem', color: '#71717a' }}>
                    ({selectedDriver.driver_details?.rating_count || 0} reviews)
                  </span>
                </div>
              </div>

              <div style={{ background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '0.85rem' }}>
                <span style={{ fontSize: '0.68rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                  Completed Trips
                </span>
                <div style={{ fontSize: '1.15rem', fontWeight: 700, color: '#fff', fontVariantNumeric: 'tabular-nums', marginTop: '0.4rem' }}>
                  {selectedDriver.completed_rides} Trips
                </div>
              </div>
            </div>

            {/* Vehicle Assignment */}
            <div style={{ background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '1rem', marginBottom: '0.5rem' }}>
              <span style={{ fontSize: '0.7rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                Assigned Vehicle Specification
              </span>
              {selectedDriver.vehicle ? (
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '0.75rem' }}>
                  <div>
                    <div style={{ fontSize: '0.9rem', fontWeight: 600, color: '#fff' }}>
                      {selectedDriver.vehicle.year} {selectedDriver.vehicle.make} {selectedDriver.vehicle.model}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: '#71717a', marginTop: 2 }}>
                      Color: {selectedDriver.vehicle.color || 'Unspecified'}
                    </div>
                  </div>
                  <span className="admin-plate-badge" style={{ fontSize: '0.8rem', padding: '3px 8px' }}>
                    {selectedDriver.vehicle.license_plate}
                  </span>
                </div>
              ) : (
                <div style={{ marginTop: '0.5rem', color: '#71717a', fontSize: '0.82rem', fontStyle: 'italic' }}>
                  No vehicle currently registered or assigned.
                </div>
              )}
            </div>

            {/* Quick Status Toggles */}
            <div style={{ background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '1rem' }}>
              <span style={{ fontSize: '0.7rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                Administrative Actions
              </span>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', marginTop: '0.75rem' }}>
                <button
                  className="admin-btn admin-btn-outline"
                  style={{ width: '100%', justifyContent: 'center' }}
                  onClick={() => navigate(`/admin/documents?driver=${selectedDriver.id}`)}
                >
                  <FileText size={14} /> View Documents & Compliance
                </button>
                {selectedDriver.driver_details?.status !== 'approved' ? (
                  <button 
                    className="admin-btn" 
                    style={{ width: '100%', justifyContent: 'center' }}
                    disabled={actionLoading}
                    onClick={() => handleStatusChange(selectedDriver.id, 'approved')}
                  >
                    <UserCheck size={14} /> Approve Chauffeur
                  </button>
                ) : (
                  <InlineConfirmButton
                    label={<><UserX size={14} style={{ marginRight: 6 }} /> Suspend Chauffeur</>}
                    confirmLabel="Confirm Suspension?"
                    disabled={actionLoading}
                    className="admin-btn admin-btn-outline"
                    confirmClassName="admin-btn admin-btn-danger"
                    style={{ width: '100%', justifyContent: 'center', color: '#ef4444', borderColor: 'rgba(239, 68, 68, 0.3)' }}
                    onConfirm={() => handleStatusChange(selectedDriver.id, 'suspended')}
                  />
                )}
              </div>
            </div>
          </>
        )}
      </AdminDrawer>

    </div>
  );
}
