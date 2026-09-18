import { useEffect, useState, useCallback, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { 
  Users, 
  CarFront,
  Car,
  Map, 
  CircleDollarSign, 
  Ticket,
  CheckCircle2,
  TrendingUp,
  TrendingDown,
  Clock,
  RefreshCw,
  ChevronRight,
  ArrowUpRight,
  Activity,
  AlertCircle
} from 'lucide-react';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer,
  BarChart, Bar
} from 'recharts';

interface DashboardStats {
  total_users: number;
  total_passengers: number;
  total_drivers: number;
  approved_drivers: number;
  pending_drivers: number;
  online_drivers: number;
  total_rides: number;
  active_rides: number;
  completed_rides: number;
  total_revenue: number;
  open_tickets: number;
  pending_documents: number;
  total_vehicles: number;
}

interface RecentRide {
  id: string;
  fare_amount: number;
  status: string;
  pickup_address: string;
  dropoff_address: string;
  created_at: string;
  passenger_name: string;
  driver_name: string | null;
}

type PeriodOption = '7d' | '14d' | '30d';

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

function buildPeriodRange(daysCount: number) {
  const now = new Date();
  const days: { name: string; start: Date; end: Date }[] = [];
  for (let i = daysCount - 1; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    const dayLabel = daysCount <= 7 
      ? DAY_NAMES[d.getDay()] 
      : `${d.toLocaleDateString(undefined, { month: 'numeric', day: 'numeric' })}`;
    days.push({
      name: dayLabel,
      start: new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0),
      end: new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1, 0, 0, 0),
    });
  }
  return days;
}

function buildPreviousPeriodRange(daysCount: number) {
  const now = new Date();
  const days: { start: Date; end: Date }[] = [];
  for (let i = daysCount - 1; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - daysCount - i);
    days.push({
      start: new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0),
      end: new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1, 0, 0, 0),
    });
  }
  return days;
}

function formatRelativeTime(dateStr: string) {
  const now = new Date();
  const date = new Date(dateStr);
  const diffSec = Math.floor((now.getTime() - date.getTime()) / 1000);
  if (diffSec < 60) return 'Just now';
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHours = Math.floor(diffMin / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function statusBadgeClass(status: string) {
  switch (status.toLowerCase()) {
    case 'completed': return 'admin-badge-success';
    case 'in_progress':
    case 'arriving':
    case 'accepted': return 'admin-badge-info';
    case 'requested': return 'admin-badge-warning';
    case 'cancelled': return 'admin-badge-danger';
    default: return '';
  }
}

function statusLabel(status: string) {
  switch (status.toLowerCase()) {
    case 'completed': return 'Completed';
    case 'in_progress': return 'In Progress';
    case 'arriving': return 'Chauffeur Arriving';
    case 'accepted': return 'Accepted';
    case 'requested': return 'Requested';
    case 'cancelled': return 'Cancelled';
    default: return status;
  }
}

// Custom Tooltip for Clean UI
interface CustomTooltipProps {
  active?: boolean;
  payload?: Array<{ value: number }>;
  label?: string;
  isCurrency?: boolean;
}

function CleanTooltip({ active, payload, label, isCurrency }: CustomTooltipProps) {
  if (active && payload && payload.length) {
    const rawVal = payload[0].value;
    const formattedVal = isCurrency ? `$${Number(rawVal).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : `${rawVal} rides`;
    return (
      <div className="admin-custom-tooltip">
        <div className="admin-tooltip-label">{label}</div>
        <div className="admin-tooltip-value">{formattedVal}</div>
      </div>
    );
  }
  return null;
}

export default function Overview() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  // Real dynamic telemetry
  const [telemetryLatency, setTelemetryLatency] = useState<number | null>(null);
  const [lastSyncTime, setLastSyncTime] = useState<Date>(new Date());
  
  // Additional dynamic metrics
  const [pendingVehicleRequests, setPendingVehicleRequests] = useState<number>(0);
  const [fleetCarsCount, setFleetCarsCount] = useState<number>(0);
  
  // Chart and time periods
  const [selectedPeriod, setSelectedPeriod] = useState<PeriodOption>('7d');
  const [revenueData, setRevenueData] = useState<{ name: string; amount: number }[]>([]);
  const [ridesData, setRidesData] = useState<{ name: string; rides: number }[]>([]);
  const [revenueChange, setRevenueChange] = useState<number>(0);

  // Recent journeys feed
  const [recentRides, setRecentRides] = useState<RecentRide[]>([]);
  const [loadingRecentRides, setLoadingRecentRides] = useState(true);

  const daysCount = useMemo(() => {
    switch (selectedPeriod) {
      case '14d': return 14;
      case '30d': return 30;
      default: return 7;
    }
  }, [selectedPeriod]);

  // Measure roundtrip latency to Supabase
  const measureTelemetry = useCallback(async () => {
    const start = performance.now();
    try {
      await supabase.from('profiles').select('id', { count: 'exact', head: true });
      const duration = Math.round(performance.now() - start);
      setTelemetryLatency(duration);
    } catch {
      setTelemetryLatency(null);
    }
  }, []);

  // Fetch admin dashboard RPC stats
  const fetchStats = useCallback(async () => {
    try {
      const { data, error } = await supabase.rpc('get_admin_dashboard_stats');
      if (error) throw error;
      setStats(data as DashboardStats);
    } catch (err) {
      setError('Failed to load dashboard stats');
    }
  }, []);

  // Fetch fleet & vehicle requests count
  const fetchFleetMetrics = useCallback(async () => {
    try {
      const [fleetRes, reqRes] = await Promise.all([
        supabase.from('fleet_cars').select('id', { count: 'exact', head: true }).is('deleted_at', null),
        supabase.from('vehicle_requests').select('id', { count: 'exact', head: true }).eq('status', 'pending')
      ]);
      setFleetCarsCount(fleetRes.count || 0);
      setPendingVehicleRequests(reqRes.count || 0);
    } catch {
      // Ignore if table not present
    }
  }, []);

  // Fetch chart data according to selected period
  const fetchChartData = useCallback(async (daysToFetch: number) => {
    try {
      const now = new Date();
      const cutoffDate = new Date(now);
      cutoffDate.setDate(cutoffDate.getDate() - (daysToFetch * 2));

      const { data: rides, error } = await supabase
        .from('rides')
        .select('created_at, fare_amount, status')
        .in('status', ['completed'])
        .gte('created_at', cutoffDate.toISOString())
        .order('created_at');

      if (error) throw error;

      const currentDays = buildPeriodRange(daysToFetch);
      const previousDays = buildPreviousPeriodRange(daysToFetch);

      const currentRevenueList = currentDays.map((day) => {
        const dayRides = (rides || []).filter((r) => {
          const c = new Date(r.created_at);
          return c >= day.start && c < day.end;
        });
        return {
          name: day.name,
          amount: dayRides.reduce((sum, r) => sum + Number(r.fare_amount || 0), 0),
        };
      });

      const currentRidesList = currentDays.map((day) => {
        const dayRides = (rides || []).filter((r) => {
          const c = new Date(r.created_at);
          return c >= day.start && c < day.end;
        });
        return { name: day.name, rides: dayRides.length };
      });

      const previousRevenueTotal = previousDays.reduce((sum, day) => {
        const dayRides = (rides || []).filter((r) => {
          const c = new Date(r.created_at);
          return c >= day.start && c < day.end;
        });
        return sum + dayRides.reduce((s, r) => s + Number(r.fare_amount || 0), 0);
      }, 0);

      const currentRevenueTotal = currentRevenueList.reduce((sum, d) => sum + d.amount, 0);
      const change = previousRevenueTotal > 0
        ? ((currentRevenueTotal - previousRevenueTotal) / previousRevenueTotal) * 100
        : currentRevenueTotal > 0
          ? 100
          : 0;

      setRevenueData(currentRevenueList);
      setRidesData(currentRidesList);
      setRevenueChange(change);
    } catch {
      setRevenueData([]);
      setRidesData([]);
    }
  }, []);

  // Fetch recent journeys for the live feed
  const fetchRecentRides = useCallback(async () => {
    try {
      setLoadingRecentRides(true);
      const { data: rawRides, error: ridesErr } = await supabase
        .from('rides')
        .select('id, fare_amount, status, pickup_address, dropoff_address, created_at, passenger_id, driver_id')
        .order('created_at', { ascending: false })
        .limit(5);

      if (ridesErr) throw ridesErr;

      const profileIds = new Set<string>();
      (rawRides || []).forEach((r) => {
        if (r.passenger_id) profileIds.add(r.passenger_id);
        if (r.driver_id) profileIds.add(r.driver_id);
      });

      const profileMap: Record<string, string> = {};
      if (profileIds.size > 0) {
        const { data: profiles } = await supabase
          .from('profiles')
          .select('id, first_name, last_name, email')
          .in('id', Array.from(profileIds));

        (profiles || []).forEach((p) => {
          const name = [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email || 'Client';
          profileMap[p.id] = name;
        });
      }

      const formatted: RecentRide[] = (rawRides || []).map((r) => ({
        id: r.id,
        fare_amount: Number(r.fare_amount || 0),
        status: r.status,
        pickup_address: r.pickup_address || 'Pickup Point',
        dropoff_address: r.dropoff_address || 'Destination Point',
        created_at: r.created_at,
        passenger_name: profileMap[r.passenger_id] || 'Executive Guest',
        driver_name: r.driver_id ? (profileMap[r.driver_id] || 'Chauffeur Assigned') : null,
      }));

      setRecentRides(formatted);
    } catch {
      setRecentRides([]);
    } finally {
      setLoadingRecentRides(false);
    }
  }, []);

  // Load all dashboard components
  const loadAll = useCallback(async (isManualRefresh = false) => {
    if (isManualRefresh) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }
    setError(null);

    await Promise.all([
      measureTelemetry(),
      fetchStats(),
      fetchFleetMetrics(),
      fetchChartData(daysCount),
      fetchRecentRides(),
    ]);
    
    setLastSyncTime(new Date());
    setLoading(false);
    setRefreshing(false);
  }, [measureTelemetry, fetchStats, fetchFleetMetrics, fetchChartData, fetchRecentRides, daysCount]);

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  // When period changes, reload chart
  useEffect(() => {
    fetchChartData(daysCount);
  }, [daysCount, fetchChartData]);

  // Derived metrics
  const currentPeriodRevenueTotal = revenueData.reduce((acc, curr) => acc + curr.amount, 0);
  const currentPeriodRidesTotal = ridesData.reduce((acc, curr) => acc + curr.rides, 0);

  const approvalRate = stats && stats.total_drivers > 0
    ? Math.round((stats.approved_drivers / stats.total_drivers) * 100)
    : 0;

  const onlineDriverRate = stats && stats.approved_drivers > 0
    ? Math.round((stats.online_drivers / stats.approved_drivers) * 100)
    : 0;

  const clientPercentage = stats && stats.total_users > 0
    ? Math.round((stats.total_passengers / stats.total_users) * 100)
    : 0;

  const attentionTotal = 
    (stats?.open_tickets || 0) + 
    (stats?.pending_drivers || 0) + 
    (stats?.pending_documents || 0) +
    pendingVehicleRequests;

  const isPositiveRevenue = revenueChange >= 0;

  // Shimmer Skeleton Loader for initial load
  if (loading && !stats) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
          <div>
            <div className="admin-skeleton" style={{ width: 180, height: 26, marginBottom: 8 }} />
            <div className="admin-skeleton" style={{ width: 280, height: 16 }} />
          </div>
          <div className="admin-skeleton" style={{ width: 140, height: 34 }} />
        </div>

        <div className="admin-stats-grid">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="admin-card" style={{ height: 130 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <div className="admin-skeleton" style={{ width: 90, height: 14 }} />
                <div className="admin-skeleton" style={{ width: 36, height: 36, borderRadius: 8 }} />
              </div>
              <div className="admin-skeleton" style={{ width: 120, height: 30, margin: '12px 0 8px' }} />
              <div className="admin-skeleton" style={{ width: 100, height: 16 }} />
            </div>
          ))}
        </div>

        <div className="admin-charts-grid">
          {[1, 2].map((i) => (
            <div key={i} className="admin-card admin-chart-card">
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 20 }}>
                <div className="admin-skeleton" style={{ width: 140, height: 20 }} />
                <div className="admin-skeleton" style={{ width: 70, height: 20 }} />
              </div>
              <div className="admin-skeleton" style={{ flex: 1, width: '100%', borderRadius: 8 }} />
            </div>
          ))}
        </div>
      </div>
    );
  }

  // Error view
  if (error && !stats) {
    return (
      <div className="admin-card" style={{ padding: '3rem 2rem', textAlign: 'center', maxWidth: 480, margin: '5vh auto' }}>
        <div style={{ width: 44, height: 44, borderRadius: '50%', background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1rem' }}>
          <AlertCircle size={22} />
        </div>
        <h3 style={{ margin: '0 0 0.5rem', fontSize: '1.1rem', color: '#fff' }}>Unable to load dashboard data</h3>
        <p style={{ color: '#a1a1aa', fontSize: '0.875rem', margin: '0 0 1.5rem' }}>{error}</p>
        <button className="admin-btn" onClick={() => loadAll(false)}>
          <RefreshCw size={14} /> Try Again
        </button>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Overview Command Center Header */}
      <div className="admin-overview-header">
        <div>
          <h2 className="admin-overview-title">Command Center</h2>
          <p className="admin-overview-subtitle">Live platform operations, fleet telemetry, and executive performance metrics</p>
        </div>

        <div className="admin-overview-actions">
          {/* Dynamic Live Telemetry Status */}
          <div 
            className="admin-live-pill" 
            title={telemetryLatency !== null ? `Supabase response roundtrip: ${telemetryLatency}ms` : 'Connecting to database...'}
          >
            <span 
              className="admin-live-dot" 
              style={{ 
                backgroundColor: telemetryLatency === null ? '#ef4444' : telemetryLatency > 600 ? '#f59e0b' : 'var(--admin-success)' 
              }} 
            />
            <span>
              {telemetryLatency !== null 
                ? `${telemetryLatency}ms • Online` 
                : 'Connecting...'}
            </span>
          </div>

          {/* Interactive Period Selector */}
          <div className="admin-period-tabs" style={{ display: 'flex', background: 'rgba(255, 255, 255, 0.04)', borderRadius: 8, padding: 2, border: '1px solid var(--admin-border)' }}>
            {(['7d', '14d', '30d'] as PeriodOption[]).map((period) => (
              <button
                key={period}
                type="button"
                onClick={() => setSelectedPeriod(period)}
                style={{
                  background: selectedPeriod === period ? 'rgba(244, 197, 34, 0.15)' : 'transparent',
                  color: selectedPeriod === period ? 'var(--admin-primary)' : 'var(--admin-text-muted)',
                  border: selectedPeriod === period ? '1px solid rgba(244, 197, 34, 0.3)' : '1px solid transparent',
                  borderRadius: 6,
                  padding: '4px 10px',
                  fontSize: '0.72rem',
                  fontWeight: selectedPeriod === period ? 700 : 500,
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                }}
              >
                {period === '7d' ? '7 Days' : period === '14d' ? '14 Days' : '30 Days'}
              </button>
            ))}
          </div>

          {/* Manual Refresh / Sync Button */}
          <button 
            className="admin-refresh-btn" 
            onClick={() => loadAll(true)}
            disabled={refreshing}
            title={`Last synced: ${lastSyncTime.toLocaleTimeString()}`}
          >
            <RefreshCw size={13} className={refreshing ? 'admin-spin' : ''} />
            <span>{refreshing ? 'Syncing...' : 'Sync'}</span>
          </button>
        </div>
      </div>

      {/* Primary KPI Metric Cards */}
      <div className="admin-stats-grid">
        
        {/* Total Revenue Card */}
        <div className="admin-card admin-card-interactive admin-stat-card">
          <div style={{ flex: 1, minWidth: 0 }}>
            <span className="admin-stat-label">Total Revenue</span>
            <h3 className="admin-stat-value">${(stats?.total_revenue || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</h3>
            <div className="admin-stat-footer">
              <span className={`admin-stat-delta ${isPositiveRevenue ? 'positive' : 'negative'}`}>
                {isPositiveRevenue ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
                {isPositiveRevenue ? '+' : ''}{revenueChange.toFixed(1)}% vs prior {daysCount}d
              </span>
              <p className="admin-stat-subtext">{daysCount}d gross: ${currentPeriodRevenueTotal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
            </div>
          </div>
          <div className="admin-stat-icon" style={{ background: 'rgba(244, 197, 34, 0.08)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
            <CircleDollarSign size={20} />
          </div>
        </div>

        {/* Active Journeys Card */}
        <div className="admin-card admin-card-interactive admin-stat-card">
          <div style={{ flex: 1, minWidth: 0 }}>
            <span className="admin-stat-label">Active Journeys</span>
            <h3 className="admin-stat-value">{stats?.active_rides || 0}</h3>
            <div className="admin-stat-footer">
              {(stats?.active_rides || 0) > 0 ? (
                <span className="admin-stat-delta info">
                  <Map size={12} /> Live En Route
                </span>
              ) : (
                <span className="admin-stat-delta neutral">
                  <Clock size={12} /> Standby Ready
                </span>
              )}
              <p className="admin-stat-subtext">
                {(stats?.active_rides || 0) > 0 
                  ? 'Active executive trips in progress' 
                  : `${stats?.completed_rides || 0} completed rides lifetime`}
              </p>
            </div>
          </div>
          <div className="admin-stat-icon" style={{ background: 'rgba(59, 130, 246, 0.08)', color: 'var(--admin-info)', borderColor: 'rgba(59, 130, 246, 0.2)' }}>
            <Map size={20} />
          </div>
        </div>

        {/* Total Users Card */}
        <div className="admin-card admin-card-interactive admin-stat-card">
          <div style={{ flex: 1, minWidth: 0 }}>
            <span className="admin-stat-label">Platform Accounts</span>
            <h3 className="admin-stat-value">{stats?.total_users || 0}</h3>
            <div className="admin-stat-footer">
              <span className="admin-stat-delta neutral">
                <Users size={12} /> {clientPercentage}% Clients
              </span>
              <p className="admin-stat-subtext">{stats?.total_passengers || 0} clients • {stats?.total_drivers || 0} chauffeurs</p>
            </div>
          </div>
          <div className="admin-stat-icon" style={{ background: 'rgba(255, 255, 255, 0.04)', color: 'var(--admin-text)', borderColor: 'rgba(255, 255, 255, 0.08)' }}>
            <Users size={20} />
          </div>
        </div>

        {/* Online Chauffeurs Card */}
        <div className="admin-card admin-card-interactive admin-stat-card">
          <div style={{ flex: 1, minWidth: 0 }}>
            <span className="admin-stat-label">Chauffeurs On Standby</span>
            <h3 className="admin-stat-value">{stats?.online_drivers || 0}</h3>
            <div className="admin-stat-footer">
              {(stats?.online_drivers || 0) > 0 ? (
                <span className="admin-stat-delta positive">
                  <CheckCircle2 size={12} /> {onlineDriverRate}% On Duty
                </span>
              ) : (
                <span className="admin-stat-delta neutral">
                  <Clock size={12} /> Off Duty
                </span>
              )}
              <p className="admin-stat-subtext">{stats?.online_drivers || 0} of {stats?.approved_drivers || 0} certified online</p>
            </div>
          </div>
          <div className="admin-stat-icon" style={{ background: 'rgba(16, 185, 129, 0.08)', color: 'var(--admin-success)', borderColor: 'rgba(16, 185, 129, 0.2)' }}>
            <CarFront size={20} />
          </div>
        </div>

      </div>

      {/* Performance Analytics Grid */}
      <div className="admin-charts-grid">
        
        {/* Revenue Flow Chart */}
        <div className="admin-card admin-chart-card">
          <div className="admin-chart-header-row">
            <div>
              <div className="admin-chart-title-area">
                <CircleDollarSign size={16} color="var(--admin-primary)" />
                <h4 className="admin-chart-title">Revenue Trajectory ({daysCount} Days)</h4>
              </div>
              <div className="admin-chart-kpi">${currentPeriodRevenueTotal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</div>
            </div>
            <span className="admin-chart-tag">Daily Fares</span>
          </div>

          <div style={{ flex: 1, width: '100%', minHeight: 220 }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueData} margin={{ top: 10, right: 8, bottom: 0, left: -22 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255, 255, 255, 0.04)" vertical={false} />
                <XAxis 
                  dataKey="name" 
                  stroke="#52525b" 
                  fontSize={11} 
                  tickLine={false} 
                  axisLine={{ stroke: 'rgba(255, 255, 255, 0.06)' }} 
                  dy={8} 
                />
                <YAxis 
                  stroke="#52525b" 
                  fontSize={11} 
                  tickLine={false} 
                  axisLine={false} 
                  tickFormatter={(val) => val >= 1000 ? `$${(val / 1000).toFixed(0)}k` : `$${val}`} 
                />
                <RechartsTooltip 
                  content={<CleanTooltip isCurrency={true} />} 
                  cursor={{ stroke: 'rgba(244, 197, 34, 0.25)', strokeWidth: 1, strokeDasharray: '4 4' }} 
                />
                <Area 
                  type="monotone" 
                  dataKey="amount" 
                  stroke="#F4C522" 
                  strokeWidth={2} 
                  fill="rgba(244, 197, 34, 0.06)" 
                  activeDot={{ r: 4, fill: '#F4C522', stroke: '#09090b', strokeWidth: 2 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Rides Volume Chart */}
        <div className="admin-card admin-chart-card">
          <div className="admin-chart-header-row">
            <div>
              <div className="admin-chart-title-area">
                <Map size={16} color="var(--admin-info)" />
                <h4 className="admin-chart-title">Completed Trips ({daysCount} Days)</h4>
              </div>
              <div className="admin-chart-kpi">{currentPeriodRidesTotal} Trips</div>
            </div>
            <span className="admin-chart-tag">Ride Volume</span>
          </div>

          <div style={{ flex: 1, width: '100%', minHeight: 220 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={ridesData} margin={{ top: 10, right: 8, bottom: 0, left: -22 }} barSize={daysCount > 14 ? 14 : 26}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255, 255, 255, 0.04)" vertical={false} />
                <XAxis 
                  dataKey="name" 
                  stroke="#52525b" 
                  fontSize={11} 
                  tickLine={false} 
                  axisLine={{ stroke: 'rgba(255, 255, 255, 0.06)' }} 
                  dy={8} 
                />
                <YAxis 
                  stroke="#52525b" 
                  fontSize={11} 
                  tickLine={false} 
                  axisLine={false} 
                  allowDecimals={false}
                />
                <RechartsTooltip 
                  content={<CleanTooltip isCurrency={false} />} 
                  cursor={{ fill: 'rgba(255, 255, 255, 0.03)' }} 
                />
                <Bar 
                  dataKey="rides" 
                  fill="var(--admin-info)" 
                  radius={[4, 4, 0, 0]} 
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

      </div>

      {/* Live Recent Activity Feed */}
      <div className="admin-card">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.25rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Activity size={16} color="var(--admin-primary)" />
            <h4 style={{ margin: 0, fontSize: '0.98rem', fontWeight: 600 }}>Recent Journey Activity</h4>
          </div>
          <Link to="/admin/rides" className="admin-link" style={{ fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: 4 }}>
            <span>View All Journeys</span>
            <ChevronRight size={14} />
          </Link>
        </div>

        {loadingRecentRides ? (
          <div style={{ padding: '2rem 1rem', textAlign: 'center' }}>
            <div className="admin-skeleton" style={{ width: '100%', height: 40, marginBottom: 8 }} />
            <div className="admin-skeleton" style={{ width: '100%', height: 40, marginBottom: 8 }} />
            <div className="admin-skeleton" style={{ width: '100%', height: 40 }} />
          </div>
        ) : recentRides.length === 0 ? (
          <div style={{ padding: '2.5rem 1rem', textAlign: 'center', color: 'var(--admin-text-muted)', fontSize: '0.88rem' }}>
            No recorded journey activity yet. Rides booked via website or app will appear here in real time.
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="admin-table">
              <thead>
                <tr>
                  <th scope="col" style={{ width: '110px' }}>Journey</th>
                  <th scope="col">Client</th>
                  <th scope="col">Route</th>
                  <th scope="col">Chauffeur</th>
                  <th scope="col" style={{ width: '100px' }}>Fare</th>
                  <th scope="col" style={{ width: '130px' }}>Status</th>
                  <th scope="col" style={{ width: '90px', textAlign: 'right' }}>Time</th>
                </tr>
              </thead>
              <tbody>
                {recentRides.map((ride) => (
                  <tr key={ride.id}>
                    <td data-label="Journey">
                      <span style={{ fontFamily: 'monospace', fontSize: '0.8rem', color: '#a1a1aa' }}>
                        #{ride.id.slice(0, 8)}
                      </span>
                    </td>
                    <td data-label="Client">
                      <div className="admin-table-user-cell">
                        <div className="admin-avatar-small">
                          {ride.passenger_name.charAt(0).toUpperCase()}
                        </div>
                        <span style={{ fontWeight: 600, color: '#fff', fontSize: '0.84rem' }}>
                          {ride.passenger_name}
                        </span>
                      </div>
                    </td>
                    <td data-label="Route">
                      <div className="admin-route-preview">
                        <div className="admin-route-stop" title={ride.pickup_address}>
                          <span className="admin-route-dot pickup" />
                          <span style={{ color: '#e4e4e7', fontSize: '0.8rem' }}>{ride.pickup_address}</span>
                        </div>
                        <div className="admin-route-connector" />
                        <div className="admin-route-stop" title={ride.dropoff_address}>
                          <span className="admin-route-dot dropoff" />
                          <span style={{ color: '#a1a1aa', fontSize: '0.8rem' }}>{ride.dropoff_address}</span>
                        </div>
                      </div>
                    </td>
                    <td data-label="Chauffeur">
                      {ride.driver_name ? (
                        <div className="admin-table-user-cell">
                          <div className="admin-avatar-small" style={{ background: 'rgba(244, 197, 34, 0.1)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
                            <CarFront size={13} />
                          </div>
                          <span style={{ color: '#fff', fontSize: '0.82rem' }}>{ride.driver_name}</span>
                        </div>
                      ) : (
                        <span style={{ color: '#71717a', fontSize: '0.78rem' }}>Awaiting Dispatch</span>
                      )}
                    </td>
                    <td data-label="Fare">
                      <span style={{ fontWeight: 600, color: '#F4C522', fontSize: '0.86rem' }}>
                        ${ride.fare_amount.toFixed(2)}
                      </span>
                    </td>
                    <td data-label="Status">
                      <span className={`admin-badge ${statusBadgeClass(ride.status)}`}>
                        {statusLabel(ride.status)}
                      </span>
                    </td>
                    <td data-label="Time" style={{ textAlign: 'right' }}>
                      <span style={{ fontSize: '0.75rem', color: '#71717a' }}>
                        {formatRelativeTime(ride.created_at)}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Actionable Insights & Operations Breakdown */}
      <div className="admin-insights-grid">
        
        {/* Attention Queue Card */}
        <div className="admin-card">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Ticket size={16} color="var(--admin-warning)" />
              <h4 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 600 }}>Action Required</h4>
            </div>
            <span className={`admin-badge ${attentionTotal > 0 ? 'admin-badge-warning' : 'admin-badge-success'}`}>
              {attentionTotal > 0 ? `${attentionTotal} Pending Actions` : 'All Clear'}
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
            
            {/* Open Support Tickets */}
            <Link to="/admin/support" className="admin-action-item">
              <div className="admin-action-left">
                <span className="admin-action-indicator" style={{ background: stats?.open_tickets ? 'var(--admin-danger)' : '#52525b' }} />
                <div>
                  <p className="admin-action-title">Support Tickets</p>
                  <p className="admin-action-sub">{stats?.open_tickets ? `${stats.open_tickets} customer queries awaiting response` : 'No open support tickets'}</p>
                </div>
              </div>
              <div className="admin-action-right">
                <span className={`admin-badge ${stats?.open_tickets ? 'admin-badge-danger' : ''}`} style={!stats?.open_tickets ? { background: 'rgba(255,255,255,0.04)', color: '#71717a' } : undefined}>
                  {stats?.open_tickets || 0}
                </span>
                <ChevronRight size={15} className="admin-action-arrow" />
              </div>
            </Link>

            {/* Pending Chauffeur Approvals */}
            <Link to="/admin/drivers" className="admin-action-item">
              <div className="admin-action-left">
                <span className="admin-action-indicator" style={{ background: stats?.pending_drivers ? 'var(--admin-warning)' : '#52525b' }} />
                <div>
                  <p className="admin-action-title">Chauffeur Approvals</p>
                  <p className="admin-action-sub">{stats?.pending_drivers ? `${stats.pending_drivers} chauffeur applications waiting for review` : 'All chauffeur applications reviewed'}</p>
                </div>
              </div>
              <div className="admin-action-right">
                <span className={`admin-badge ${stats?.pending_drivers ? 'admin-badge-warning' : ''}`} style={!stats?.pending_drivers ? { background: 'rgba(255,255,255,0.04)', color: '#71717a' } : undefined}>
                  {stats?.pending_drivers || 0}
                </span>
                <ChevronRight size={15} className="admin-action-arrow" />
              </div>
            </Link>

            {/* Pending Documents */}
            <Link to="/admin/documents" className="admin-action-item">
              <div className="admin-action-left">
                <span className="admin-action-indicator" style={{ background: stats?.pending_documents ? 'var(--admin-info)' : '#52525b' }} />
                <div>
                  <p className="admin-action-title">Document Verifications</p>
                  <p className="admin-action-sub">{stats?.pending_documents ? `${stats.pending_documents} licenses & proofs awaiting verification` : 'All compliance documents verified'}</p>
                </div>
              </div>
              <div className="admin-action-right">
                <span className={`admin-badge ${stats?.pending_documents ? 'admin-badge-info' : ''}`} style={!stats?.pending_documents ? { background: 'rgba(255,255,255,0.04)', color: '#71717a' } : undefined}>
                  {stats?.pending_documents || 0}
                </span>
                <ChevronRight size={15} className="admin-action-arrow" />
              </div>
            </Link>

            {/* Pending Fleet Vehicle Requests */}
            <Link to="/admin/fleet" className="admin-action-item">
              <div className="admin-action-left">
                <span className="admin-action-indicator" style={{ background: pendingVehicleRequests ? 'var(--admin-primary)' : '#52525b' }} />
                <div>
                  <p className="admin-action-title">Vehicle Registration Requests</p>
                  <p className="admin-action-sub">{pendingVehicleRequests ? `${pendingVehicleRequests} driver vehicle requests to approve` : 'No pending vehicle requests'}</p>
                </div>
              </div>
              <div className="admin-action-right">
                <span className={`admin-badge ${pendingVehicleRequests ? 'admin-badge-warning' : ''}`} style={!pendingVehicleRequests ? { background: 'rgba(255,255,255,0.04)', color: '#71717a' } : undefined}>
                  {pendingVehicleRequests}
                </span>
                <ChevronRight size={15} className="admin-action-arrow" />
              </div>
            </Link>

          </div>
        </div>

        {/* System & Fleet Health Card */}
        <div className="admin-card">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Activity size={16} color="var(--admin-success)" />
              <h4 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 600 }}>Fleet & Telemetry Health</h4>
            </div>
            <span className={`admin-badge ${telemetryLatency === null ? 'admin-badge-danger' : telemetryLatency > 600 ? 'admin-badge-warning' : 'admin-badge-success'}`}>
              {telemetryLatency === null ? 'Offline' : telemetryLatency > 600 ? 'Latency Alert' : 'Operational'}
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            
            {/* Fleet Inventory */}
            <div className="admin-health-row">
              <div className="admin-health-label-area">
                <Car size={15} color="var(--admin-text-muted)" />
                <span className="admin-health-label">Fleet Inventory</span>
              </div>
              <span className="admin-health-value">
                {fleetCarsCount > 0 ? `${fleetCarsCount} Fleet Models (${stats?.total_vehicles || 0} Registered Cars)` : `${stats?.total_vehicles || 0} Vehicles`}
              </span>
            </div>

            {/* Chauffeur Onboarding Health */}
            <div className="admin-health-row" style={{ flexDirection: 'column', alignItems: 'stretch' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div className="admin-health-label-area">
                  <CarFront size={15} color="var(--admin-text-muted)" />
                  <span className="admin-health-label">Chauffeur Approval Rate</span>
                </div>
                <span className="admin-health-value">
                  {stats?.approved_drivers || 0} / {stats?.total_drivers || 0} ({approvalRate}%)
                </span>
              </div>
              <div className="admin-progress-track">
                <div 
                  className="admin-progress-fill" 
                  style={{ 
                    width: `${approvalRate}%`, 
                    backgroundColor: approvalRate >= 70 ? 'var(--admin-success)' : approvalRate >= 40 ? 'var(--admin-warning)' : 'var(--admin-info)' 
                  }} 
                />
              </div>
            </div>

            {/* All-time Completed Rides */}
            <div className="admin-health-row">
              <div className="admin-health-label-area">
                <Clock size={15} color="var(--admin-text-muted)" />
                <span className="admin-health-label">Lifetime Completed Rides</span>
              </div>
              <span className="admin-health-value">{(stats?.completed_rides || 0).toLocaleString()} trips</span>
            </div>

            {/* Live Telemetry Latency - Real Supabase Roundtrip */}
            <div className="admin-health-row">
              <div className="admin-health-label-area">
                <CheckCircle2 
                  size={15} 
                  color={telemetryLatency === null ? '#ef4444' : telemetryLatency > 600 ? '#f59e0b' : 'var(--admin-success)'} 
                />
                <span className="admin-health-label">Database Roundtrip Latency</span>
              </div>
              <span 
                style={{ 
                  fontSize: '0.78rem', 
                  color: telemetryLatency === null ? '#ef4444' : telemetryLatency > 600 ? '#f59e0b' : 'var(--admin-success)', 
                  fontWeight: 600 
                }}
              >
                {telemetryLatency !== null ? `${telemetryLatency} ms response` : 'Connection Failed'}
              </span>
            </div>

          </div>
        </div>

      </div>

      {/* Operational Quick Actions Strip */}
      <div className="admin-shortcuts-grid">
        <Link to="/admin/drivers" className="admin-shortcut-btn">
          <div className="admin-shortcut-content">
            <CarFront size={15} color="var(--admin-primary)" />
            <span>Manage Chauffeurs</span>
          </div>
          <ArrowUpRight size={14} color="var(--admin-text-faint)" />
        </Link>

        <Link to="/admin/fleet" className="admin-shortcut-btn">
          <div className="admin-shortcut-content">
            <Car size={15} color="var(--admin-info)" />
            <span>Fleet Inventory</span>
          </div>
          <ArrowUpRight size={14} color="var(--admin-text-faint)" />
        </Link>

        <Link to="/admin/support" className="admin-shortcut-btn">
          <div className="admin-shortcut-content">
            <Ticket size={15} color="var(--admin-warning)" />
            <span>Support Inbox</span>
          </div>
          <ArrowUpRight size={14} color="var(--admin-text-faint)" />
        </Link>

        <Link to="/admin/pricing" className="admin-shortcut-btn">
          <div className="admin-shortcut-content">
            <CircleDollarSign size={15} color="var(--admin-success)" />
            <span>Fare Pricing Rules</span>
          </div>
          <ArrowUpRight size={14} color="var(--admin-text-faint)" />
        </Link>
      </div>

    </div>
  );
}
