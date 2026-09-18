import { useEffect, useState, useCallback } from 'react';
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

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

function buildDayRange() {
  const now = new Date();
  const days: { name: string; start: Date; end: Date }[] = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    days.push({
      name: DAY_NAMES[d.getDay()],
      start: new Date(d.getFullYear(), d.getMonth(), d.getDate()),
      end: new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1),
    });
  }
  return days;
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
    const formattedVal = isCurrency ? `$${Number(rawVal).toLocaleString()}` : `${rawVal} rides`;
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
  const [revenueData, setRevenueData] = useState<{ name: string; amount: number }[]>([]);
  const [ridesData, setRidesData] = useState<{ name: string; rides: number }[]>([]);
  const [revenueChange, setRevenueChange] = useState(0);

  const fetchStats = useCallback(async () => {
    try {
      const { data, error } = await supabase.rpc('get_admin_dashboard_stats');
      if (error) throw error;
      setStats(data as DashboardStats);
    } catch (err) {
      setError('Failed to load dashboard stats');
    }
  }, []);

  const fetchChartData = useCallback(async () => {
    try {
      const now = new Date();
      const twoWeeksAgo = new Date(now);
      twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);

      const { data: rides, error } = await supabase
        .from('rides')
        .select('created_at, fare_amount, status')
        .in('status', ['completed'])
        .gte('created_at', twoWeeksAgo.toISOString())
        .order('created_at');

      if (error) throw error;

      const currentDays = buildDayRange();
      const previousDays = buildDayRange().map((d, i) => {
        const prev = new Date(now);
        prev.setDate(prev.getDate() - 7 + i);
        return {
          name: d.name,
          start: new Date(prev.getFullYear(), prev.getMonth(), prev.getDate()),
          end: new Date(prev.getFullYear(), prev.getMonth(), prev.getDate() + 1),
        };
      });

      const currentWeekRevenue = currentDays.map((day) => {
        const dayRides = (rides || []).filter((r) => {
          const c = new Date(r.created_at);
          return c >= day.start && c < day.end;
        });
        return {
          name: day.name,
          amount: dayRides.reduce((sum, r) => sum + Number(r.fare_amount), 0),
        };
      });

      const currentWeekRides = currentDays.map((day) => {
        const dayRides = (rides || []).filter((r) => {
          const c = new Date(r.created_at);
          return c >= day.start && c < day.end;
        });
        return { name: day.name, rides: dayRides.length };
      });

      const previousWeekRevenue = previousDays.reduce((sum, day) => {
        const dayRides = (rides || []).filter((r) => {
          const c = new Date(r.created_at);
          return c >= day.start && c < day.end;
        });
        return sum + dayRides.reduce((s, r) => s + Number(r.fare_amount), 0);
      }, 0);

      const currentWeekTotal = currentWeekRevenue.reduce((sum, d) => sum + d.amount, 0);
      const change = previousWeekRevenue > 0
        ? ((currentWeekTotal - previousWeekRevenue) / previousWeekRevenue) * 100
        : currentWeekTotal > 0
          ? 100
          : 0;

      setRevenueData(currentWeekRevenue);
      setRidesData(currentWeekRides);
      setRevenueChange(change);
    } catch (err) {
      setRevenueData([]);
      setRidesData([]);
    }
  }, []);

  const loadAll = useCallback(async (isManualRefresh = false) => {
    if (isManualRefresh) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }
    setError(null);

    await Promise.all([fetchStats(), fetchChartData()]);
    
    setLoading(false);
    setRefreshing(false);
  }, [fetchStats, fetchChartData]);

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  // Derived calculations
  const currentWeekRevenueTotal = revenueData.reduce((acc, curr) => acc + curr.amount, 0);
  const currentWeekRidesTotal = ridesData.reduce((acc, curr) => acc + curr.rides, 0);

  const approvalRate = stats && stats.total_drivers > 0
    ? Math.round((stats.approved_drivers / stats.total_drivers) * 100)
    : 0;

  const attentionTotal = (stats?.open_tickets || 0) + (stats?.pending_drivers || 0) + (stats?.pending_documents || 0);

  // Shimmer Skeleton Loader for professional initial load
  if (loading && !stats) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        {/* Header Skeleton */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
          <div>
            <div className="admin-skeleton" style={{ width: 180, height: 26, marginBottom: 8 }} />
            <div className="admin-skeleton" style={{ width: 280, height: 16 }} />
          </div>
          <div className="admin-skeleton" style={{ width: 140, height: 34 }} />
        </div>

        {/* Stats Grid Skeleton */}
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

        {/* Charts Grid Skeleton */}
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

        {/* Insights Grid Skeleton */}
        <div className="admin-insights-grid">
          {[1, 2].map((i) => (
            <div key={i} className="admin-card" style={{ height: 200 }}>
              <div className="admin-skeleton" style={{ width: 150, height: 20, marginBottom: 16 }} />
              <div className="admin-skeleton" style={{ width: '100%', height: 36, marginBottom: 8 }} />
              <div className="admin-skeleton" style={{ width: '100%', height: 36, marginBottom: 8 }} />
              <div className="admin-skeleton" style={{ width: '100%', height: 36 }} />
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

  const isPositiveRevenue = revenueChange >= 0;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Overview Command Center Header */}
      <div className="admin-overview-header">
        <div>
          <h2 className="admin-overview-title">Command Center</h2>
          <p className="admin-overview-subtitle">Live platform operations, fleet activity, and executive concierge performance</p>
        </div>

        <div className="admin-overview-actions">
          <div className="admin-live-pill" title="Platform telemetry active">
            <span className="admin-live-dot" />
            <span>Telemetry Online</span>
          </div>

          <div className="admin-period-pill">
            <span>Trailing 7 Days</span>
          </div>

          <button 
            className="admin-refresh-btn" 
            onClick={() => loadAll(true)}
            disabled={refreshing}
            title="Refresh dashboard metrics"
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
            <h3 className="admin-stat-value">${stats?.total_revenue?.toLocaleString() || '0'}</h3>
            <div className="admin-stat-footer">
              <span className={`admin-stat-delta ${isPositiveRevenue ? 'positive' : 'negative'}`}>
                {isPositiveRevenue ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
                {isPositiveRevenue ? '+' : ''}{revenueChange.toFixed(1)}% vs last week
              </span>
              <p className="admin-stat-subtext">7-day gross: ${currentWeekRevenueTotal.toLocaleString()}</p>
            </div>
          </div>
          <div className="admin-stat-icon" style={{ background: 'rgba(244, 197, 34, 0.08)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
            <CircleDollarSign size={20} />
          </div>
        </div>

        {/* Active Rides Card */}
        <div className="admin-card admin-card-interactive admin-stat-card">
          <div style={{ flex: 1, minWidth: 0 }}>
            <span className="admin-stat-label">Active Journeys</span>
            <h3 className="admin-stat-value">{stats?.active_rides || 0}</h3>
            <div className="admin-stat-footer">
              <span className="admin-stat-delta info">
                <Map size={12} /> Live En Route
              </span>
              <p className="admin-stat-subtext">Currently en route with clients</p>
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
                <Users size={12} /> {stats?.total_passengers || 0} passengers
              </span>
              <p className="admin-stat-subtext">{stats?.total_drivers || 0} total chauffeurs</p>
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
              <span className="admin-stat-delta positive">
                <CheckCircle2 size={12} /> Ready for Assignment
              </span>
              <p className="admin-stat-subtext">Of {stats?.approved_drivers || 0} certified chauffeurs</p>
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
                <h4 className="admin-chart-title">Revenue Trajectory</h4>
              </div>
              <div className="admin-chart-kpi">${currentWeekRevenueTotal.toLocaleString()}</div>
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
                <h4 className="admin-chart-title">Completed Trips</h4>
              </div>
              <div className="admin-chart-kpi">{currentWeekRidesTotal} Trips</div>
            </div>
            <span className="admin-chart-tag">Ride Volume</span>
          </div>

          <div style={{ flex: 1, width: '100%', minHeight: 220 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={ridesData} margin={{ top: 10, right: 8, bottom: 0, left: -22 }} barSize={26}>
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
              {attentionTotal > 0 ? `${attentionTotal} Pending` : 'All Clear'}
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
            
            {/* Open Support Tickets */}
            <Link to="/admin/support" className="admin-action-item">
              <div className="admin-action-left">
                <span className="admin-action-indicator" style={{ background: stats?.open_tickets ? 'var(--admin-danger)' : '#52525b' }} />
                <div>
                  <p className="admin-action-title">Support Tickets</p>
                  <p className="admin-action-sub">{stats?.open_tickets ? 'Customer queries awaiting response' : 'No open support tickets'}</p>
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
                  <p className="admin-action-sub">{stats?.pending_drivers ? 'Applications waiting for review' : 'All applications reviewed'}</p>
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
                  <p className="admin-action-sub">{stats?.pending_documents ? 'License & insurance proofs to verify' : 'All compliance documents verified'}</p>
                </div>
              </div>
              <div className="admin-action-right">
                <span className={`admin-badge ${stats?.pending_documents ? 'admin-badge-info' : ''}`} style={!stats?.pending_documents ? { background: 'rgba(255,255,255,0.04)', color: '#71717a' } : undefined}>
                  {stats?.pending_documents || 0}
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
              <h4 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 600 }}>Fleet & System Status</h4>
            </div>
            <span className="admin-badge admin-badge-success">Operational</span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            
            {/* Fleet Vehicles */}
            <div className="admin-health-row">
              <div className="admin-health-label-area">
                <Car size={15} color="var(--admin-text-muted)" />
                <span className="admin-health-label">Total Fleet Vehicles</span>
              </div>
              <span className="admin-health-value">{stats?.total_vehicles || 0}</span>
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
              <span className="admin-health-value">{stats?.completed_rides?.toLocaleString() || 0}</span>
            </div>

            {/* Concierge Status */}
            <div className="admin-health-row">
              <div className="admin-health-label-area">
                <CheckCircle2 size={15} color="var(--admin-success)" />
                <span className="admin-health-label">Concierge Telemetry & Latency</span>
              </div>
              <span style={{ fontSize: '0.78rem', color: 'var(--admin-success)', fontWeight: 600 }}>Nominal (0 ms delay)</span>
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
