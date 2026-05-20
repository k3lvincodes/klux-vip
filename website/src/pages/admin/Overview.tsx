import { useEffect, useState } from 'react';
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
  Clock
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

export default function Overview() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  const revenueData = [
    { name: 'Mon', amount: 400 },
    { name: 'Tue', amount: 300 },
    { name: 'Wed', amount: 550 },
    { name: 'Thu', amount: 450 },
    { name: 'Fri', amount: 700 },
    { name: 'Sat', amount: 800 },
    { name: 'Sun', amount: 950 },
  ];

  const ridesData = [
    { name: 'Mon', rides: 24 },
    { name: 'Tue', rides: 18 },
    { name: 'Wed', rides: 35 },
    { name: 'Thu', rides: 28 },
    { name: 'Fri', rides: 45 },
    { name: 'Sat', rides: 55 },
    { name: 'Sun', rides: 62 },
  ];

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const { data, error } = await supabase.rpc('get_admin_dashboard_stats');
      if (error) throw error;
      setStats(data as DashboardStats);
    } catch (err) {
      console.error('Error fetching stats:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '50vh', color: '#a1a1aa' }}>
        Loading command center...
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      
      {/* Stat Cards Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1.25rem' }}>
        
        <div className="admin-card admin-card-interactive admin-stat-card">
          <div>
            <p className="admin-stat-label">Total Revenue</p>
            <h3 className="admin-stat-value">${stats?.total_revenue?.toLocaleString() || '0'}</h3>
            <p style={{ margin: 0, fontSize: '0.8rem', color: 'var(--admin-success)', display: 'flex', alignItems: 'center', gap: '4px' }}>
              <TrendingUp size={14} /> +12.5% this week
            </p>
          </div>
          <div className="admin-stat-icon" style={{ background: 'var(--admin-primary-dim)', color: 'var(--admin-primary)' }}>
            <CircleDollarSign size={24} />
          </div>
        </div>

        <div className="admin-card admin-card-interactive admin-stat-card">
          <div>
            <p className="admin-stat-label">Active Rides</p>
            <h3 className="admin-stat-value">{stats?.active_rides || '0'}</h3>
            <p style={{ margin: 0, fontSize: '0.8rem', color: 'var(--admin-info)', display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Map size={14} /> En route currently
            </p>
          </div>
          <div className="admin-stat-icon" style={{ background: 'var(--admin-info-dim)', color: 'var(--admin-info)' }}>
            <Map size={24} />
          </div>
        </div>

        <div className="admin-card admin-card-interactive admin-stat-card">
          <div>
            <p className="admin-stat-label">Total Users</p>
            <h3 className="admin-stat-value">{stats?.total_users || '0'}</h3>
            <p style={{ margin: 0, fontSize: '0.8rem', color: 'var(--admin-text-muted)', display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Users size={14} /> Registered accounts
            </p>
          </div>
          <div className="admin-stat-icon" style={{ background: 'rgba(255,255,255,0.05)', color: '#fff' }}>
            <Users size={24} />
          </div>
        </div>

        <div className="admin-card admin-card-interactive admin-stat-card">
          <div>
            <p className="admin-stat-label">Online Drivers</p>
            <h3 className="admin-stat-value">{stats?.online_drivers || '0'}</h3>
            <p style={{ margin: 0, fontSize: '0.8rem', color: 'var(--admin-success)', display: 'flex', alignItems: 'center', gap: '4px' }}>
              <CheckCircle2 size={14} /> Ready for dispatch
            </p>
          </div>
          <div className="admin-stat-icon" style={{ background: 'var(--admin-success-dim)', color: 'var(--admin-success)' }}>
            <CarFront size={24} />
          </div>
        </div>
      </div>

      {/* Charts Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '1.5rem' }}>
        
        {/* Revenue Chart */}
        <div className="admin-card" style={{ height: '420px', display: 'flex', flexDirection: 'column' }}>
          <div className="admin-card-title">
            <TrendingUp size={18} color="var(--admin-primary)" />
            Revenue Flow
          </div>
          <div style={{ flex: 1, width: '100%', minHeight: 0, marginTop: '1rem' }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueData} margin={{ top: 5, right: 0, bottom: 0, left: -20 }}>
                <defs>
                  <linearGradient id="colorAmount" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#F4C522" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#F4C522" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="name" stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} dy={10} />
                <YAxis stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(val) => `$${val}`} />
                <RechartsTooltip cursor={{ stroke: 'rgba(255,255,255,0.1)', strokeWidth: 1, strokeDasharray: '4 4' }} />
                <Area type="monotone" dataKey="amount" stroke="#F4C522" strokeWidth={3} fillOpacity={1} fill="url(#colorAmount)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Rides Chart */}
        <div className="admin-card" style={{ height: '420px', display: 'flex', flexDirection: 'column' }}>
          <div className="admin-card-title">
            <Map size={18} color="var(--admin-info)" />
            Rides Completed
          </div>
          <div style={{ flex: 1, width: '100%', minHeight: 0, marginTop: '1rem' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={ridesData} margin={{ top: 5, right: 0, bottom: 0, left: -20 }} barSize={32}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="name" stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} dy={10} />
                <YAxis stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                <RechartsTooltip cursor={{ fill: 'rgba(255,255,255,0.03)' }} />
                <Bar dataKey="rides" fill="var(--admin-info)" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Actionable Insights Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '1.25rem' }}>
        
        <div className="admin-card">
          <div className="admin-card-title">
            <Ticket size={18} color="var(--admin-warning)" />
            Attention Required
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', marginTop: '1rem' }}>
            
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--admin-danger)' }}></div>
                <span style={{ fontSize: '0.9rem', color: 'var(--admin-text)' }}>Open Support Tickets</span>
              </div>
              <span className="admin-badge admin-badge-danger">{stats?.open_tickets || 0}</span>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--admin-warning)' }}></div>
                <span style={{ fontSize: '0.9rem', color: 'var(--admin-text)' }}>Pending Driver Approvals</span>
              </div>
              <span className="admin-badge admin-badge-warning">{stats?.pending_drivers || 0}</span>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--admin-info)' }}></div>
                <span style={{ fontSize: '0.9rem', color: 'var(--admin-text)' }}>Pending Documents</span>
              </div>
              <span className="admin-badge admin-badge-info">{stats?.pending_documents || 0}</span>
            </div>

          </div>
        </div>

        <div className="admin-card">
          <div className="admin-card-title">
            <CheckCircle2 size={18} color="var(--admin-success)" />
            System Health
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', marginTop: '1rem' }}>
            
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <Car size={16} color="var(--admin-text-muted)" />
                <span style={{ fontSize: '0.9rem' }}>Total Vehicles</span>
              </div>
              <span style={{ fontWeight: 600 }}>{stats?.total_vehicles || 0}</span>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <CarFront size={16} color="var(--admin-text-muted)" />
                <span style={{ fontSize: '0.9rem' }}>Approved Drivers</span>
              </div>
              <span style={{ fontWeight: 600 }}>{stats?.approved_drivers || 0}</span>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <Clock size={16} color="var(--admin-text-muted)" />
                <span style={{ fontSize: '0.9rem' }}>Total Completed Rides</span>
              </div>
              <span style={{ fontWeight: 600 }}>{stats?.completed_rides || 0}</span>
            </div>

          </div>
        </div>

      </div>
    </div>
  );
}
