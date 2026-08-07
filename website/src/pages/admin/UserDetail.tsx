import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Mail, Phone, Calendar, Car, MapPin, CreditCard, Shield } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface UserProfile {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  phone: string | null;
  role: string;
  created_at: string;
  avatar_url: string | null;
}

interface Ride {
  id: string;
  pickup_address: string;
  dropoff_address: string;
  fare_amount: number;
  status: string;
  created_at: string;
}

interface PaymentMethod {
  id: string;
  type: string;
  last4: string | null;
  is_default: boolean;
}

export default function UserDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [user, setUser] = useState<UserProfile | null>(null);
  const [rides, setRides] = useState<Ride[]>([]);
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (id) fetchUserData(id);
  }, [id]);

  const fetchUserData = async (userId: string) => {
    try {
      setLoading(true);
      setError(null);

      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (profileError) throw profileError;
      setUser(profile);

      const { data: rideData } = await supabase
        .from('rides')
        .select('id, pickup_address, dropoff_address, fare_amount, status, created_at')
        .eq('passenger_id', userId)
        .order('created_at', { ascending: false })
        .limit(10);

      setRides(rideData || []);

      const { data: pmData } = await supabase
        .from('payment_methods')
        .select('id, type, last4, is_default')
        .eq('user_id', userId);

      setPaymentMethods(pmData || []);
    } catch (err: any) {
      setError(err.message || 'Failed to load user details');
    } finally {
      setLoading(false);
    }
  };

  const fullName = user
    ? [user.first_name, user.last_name].filter(Boolean).join(' ') || user.email
    : '';

  const formatDate = (iso: string) =>
    new Date(iso).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });

  const formatCurrency = (amount: number) =>
    `$${amount.toFixed(2)}`;

  const statusBadge = (status: string) => {
    const styles: Record<string, { bg: string; color: string }> = {
      completed: { bg: 'rgba(34,197,94,0.15)', color: '#22c55e' },
      cancelled: { bg: 'rgba(239,68,68,0.15)', color: '#ef4444' },
      in_progress: { bg: 'rgba(59,130,246,0.15)', color: '#3b82f6' },
      pending: { bg: 'rgba(234,179,8,0.15)', color: '#eab308' },
    };
    const s = styles[status] || { bg: 'rgba(161,161,170,0.15)', color: '#a1a1aa' };
    return (
      <span style={{ padding: '2px 10px', borderRadius: '6px', fontSize: '12px', fontWeight: 600, backgroundColor: s.bg, color: s.color }}>
        {status.charAt(0).toUpperCase() + status.slice(1).replace('_', ' ')}
      </span>
    );
  };

  if (loading) {
    return (
      <div style={{ padding: '2rem', textAlign: 'center', color: '#a1a1aa' }}>
        <div style={{ width: 40, height: 40, border: '3px solid rgba(255,255,255,0.1)', borderTopColor: '#eab308', borderRadius: '50%', margin: '0 auto 1rem', animation: 'spin 1s linear infinite' }} />
        Loading user details...
      </div>
    );
  }

  if (error || !user) {
    return (
      <div style={{ padding: '2rem', textAlign: 'center' }}>
        <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error || 'User not found'}</p>
        <button className="admin-btn" onClick={() => navigate('/admin/users')}>
          <ArrowLeft size={16} /> Back to Users
        </button>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="admin-page-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <button
            onClick={() => navigate('/admin/users')}
            style={{ background: 'none', border: 'none', color: '#a1a1aa', cursor: 'pointer', padding: '0.5rem' }}
          >
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1>User Details</h1>
            <p style={{ color: '#a1a1aa', fontSize: '14px' }}>Account information and activity</p>
          </div>
        </div>
      </div>

      {/* Profile Card */}
      <div className="admin-card" style={{ marginBottom: '1.5rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', marginBottom: '1.5rem', flexWrap: 'wrap' }}>
          <div style={{
            width: 64, height: 64, borderRadius: '50%',
            background: 'linear-gradient(135deg, #eab308, #ca8a04)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: '24px', fontWeight: 700, color: '#000',
          }}>
            {user.avatar_url ? (
              <img src={user.avatar_url} alt="" style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }} />
            ) : (
              fullName.charAt(0).toUpperCase()
            )}
          </div>
          <div>
            <h2 style={{ fontSize: '20px', fontWeight: 700, margin: 0, color: '#fff' }}>{fullName}</h2>
            <p style={{ color: '#a1a1aa', margin: '4px 0 0', fontSize: '14px' }}>{user.email}</p>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '10px' }}>
            <Mail size={16} style={{ color: '#a1a1aa' }} />
            <div>
              <p style={{ fontSize: '11px', color: '#71717a', margin: 0, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Email</p>
              <p style={{ fontSize: '14px', margin: '2px 0 0', color: '#e4e4e7' }}>{user.email}</p>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '10px' }}>
            <Phone size={16} style={{ color: '#a1a1aa' }} />
            <div>
              <p style={{ fontSize: '11px', color: '#71717a', margin: 0, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Phone</p>
              <p style={{ fontSize: '14px', margin: '2px 0 0', color: '#e4e4e7' }}>{user.phone || 'Not provided'}</p>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '10px' }}>
            <Calendar size={16} style={{ color: '#a1a1aa' }} />
            <div>
              <p style={{ fontSize: '11px', color: '#71717a', margin: 0, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Joined</p>
              <p style={{ fontSize: '14px', margin: '2px 0 0', color: '#e4e4e7' }}>{formatDate(user.created_at)}</p>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '10px' }}>
            <Shield size={16} style={{ color: '#a1a1aa' }} />
            <div>
              <p style={{ fontSize: '11px', color: '#71717a', margin: 0, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Role</p>
              <p style={{ fontSize: '14px', margin: '2px 0 0', color: '#e4e4e7', textTransform: 'capitalize' }}>{user.role || 'client'}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Payment Methods */}
      <div className="admin-card" style={{ marginBottom: '1.5rem' }}>
        <h3 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '1rem', color: '#fff', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <CreditCard size={18} /> Payment Methods
        </h3>
        {paymentMethods.length === 0 ? (
          <p style={{ color: '#71717a', fontSize: '14px' }}>No payment methods on file</p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {paymentMethods.map((pm) => (
              <div key={pm.id} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '12px 16px', background: 'rgba(255,255,255,0.03)', borderRadius: '10px',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{
                    width: 40, height: 28, borderRadius: '6px',
                    background: 'linear-gradient(135deg, rgba(234,179,8,0.2), rgba(234,179,8,0.1))',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: '11px', fontWeight: 700, color: '#eab308', textTransform: 'uppercase',
                  }}>
                    {pm.type === 'bank_account' ? 'BANK' : 'CARD'}
                  </div>
                  <div>
                    <p style={{ fontSize: '14px', margin: 0, color: '#e4e4e7' }}>
                      •••• •••• •••• {pm.last4 || '••••'}
                      {pm.is_default ? (
                        <span style={{ marginLeft: '8px', fontSize: '11px', color: '#eab308', border: '1px solid rgba(234,179,8,0.3)', borderRadius: '4px', padding: '1px 6px' }}>
                          Default
                        </span>
                      ) : null}
                    </p>
                    <p style={{ fontSize: '12px', margin: '2px 0 0', color: '#71717a' }}>
                      {pm.type === 'bank_account' ? 'Bank account' : 'Card'}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Recent Rides */}
      <div className="admin-card">
        <h3 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '1rem', color: '#fff', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Car size={18} /> Recent Rides
        </h3>
        {rides.length === 0 ? (
          <p style={{ color: '#71717a', fontSize: '14px' }}>No rides found</p>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="admin-table" style={{ margin: 0 }}>
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Route</th>
                  <th>Fare</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {rides.map((ride) => (
                  <tr key={ride.id}>
                    <td style={{ whiteSpace: 'nowrap' }}>{formatDate(ride.created_at)}</td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px' }}>
                        <MapPin size={12} style={{ color: '#22c55e', flexShrink: 0 }} />
                        <span style={{ maxWidth: 120, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{ride.pickup_address || '—'}</span>
                        <span style={{ color: '#71717a' }}>→</span>
                        <MapPin size={12} style={{ color: '#ef4444', flexShrink: 0 }} />
                        <span style={{ maxWidth: 120, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{ride.dropoff_address || '—'}</span>
                      </div>
                    </td>
                    <td style={{ fontWeight: 600 }}>{formatCurrency(ride.fare_amount)}</td>
                    <td>{statusBadge(ride.status)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
