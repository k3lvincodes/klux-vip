import { useEffect, useState, useMemo } from 'react';
import { Search, Download } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface TransactionRow {
  id: string;
  user_id: string;
  ride_id: string | null;
  amount: number;
  type: string;
  status: string;
  created_at: string;
  user_name: string;
  ride_ref: string | null;
}

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<TransactionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchTransactions();
  }, []);

  const fetchTransactions = async () => {
    try {
      const { data, error } = await supabase
        .from('transactions')
        .select('id, user_id, ride_id, amount, type, status, created_at')
        .order('created_at', { ascending: false })
        .limit(100);

      if (error) throw error;

      const userIds = [...new Set(data?.map((t) => t.user_id) || [])];
      const rideIds = [...new Set(data?.map((t) => t.ride_id).filter(Boolean) || [])];

      const [profileRes, rideRes] = await Promise.all([
        supabase
          .from('profiles')
          .select('id, first_name, last_name, email')
          .in('id', userIds.length > 0 ? userIds : ['00000000-0000-0000-0000-000000000000']),
        supabase
          .from('rides')
          .select('id, passenger_id, driver_id')
          .in('id', (rideIds as string[]).length > 0 ? (rideIds as string[]) : ['00000000-0000-0000-0000-000000000000']),
      ]);

      const nameMap = new Map<string, string>();
      profileRes.data?.forEach((p) => {
        nameMap.set(p.id, [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email);
      });

      const rideMap = new Map<string, { passenger_id: string; driver_id: string }>();
      rideRes.data?.forEach((r) => rideMap.set(r.id, r));

      setTransactions(
        (data || []).map((t) => ({
          id: t.id,
          user_id: t.user_id,
          ride_id: t.ride_id,
          amount: Number(t.amount),
          type: t.type,
          status: t.status,
          created_at: t.created_at,
          user_name: nameMap.get(t.user_id) || 'Unknown',
          ride_ref: t.ride_id ? `Ride #${t.ride_id.slice(0, 8)}` : null,
        }))
      );
    } catch (err) {
      console.error('Error fetching transactions:', err);
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    if (!search.trim()) return transactions;
    const q = search.toLowerCase();
    return transactions.filter(
      (t) =>
        t.user_name.toLowerCase().includes(q) ||
        typeLabel(t.type).toLowerCase().includes(q) ||
        t.id.toLowerCase().includes(q)
    );
  }, [transactions, search]);

  const exportCSV = () => {
    const headers = ['Transaction ID', 'Type', 'User', 'Amount', 'Date', 'Status'];
    const rows = filtered.map((t) => [
      t.id.slice(0, 8),
      typeLabel(t.type),
      t.user_name,
      `${t.amount >= 0 ? '+' : ''}$${Math.abs(t.amount).toFixed(2)}`,
      new Date(t.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }),
      statusLabel(t.status),
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `transactions_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const typeLabel = (type: string) => {
    switch (type) {
      case 'ride_payment': return 'Ride Payment';
      case 'withdrawal': return 'Chauffeur Payout';
      default: return type;
    }
  };

  const statusBadge = (status: string) => {
    switch (status) {
      case 'completed':
        return <span className="admin-badge admin-badge-success">Settled</span>;
      case 'pending':
        return <span className="admin-badge admin-badge-warning">Pending</span>;
      case 'failed':
        return <span className="admin-badge admin-badge-danger">Failed</span>;
      default:
        return <span className="admin-badge">{status}</span>;
    }
  };

  const statusLabel = (s: string) => {
    switch (s) {
      case 'completed': return 'Settled';
      case 'pending': return 'Pending';
      case 'failed': return 'Failed';
      default: return s;
    }
  };

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Transaction Ledger</h1>
          <p>Track ride payments, chauffeur payouts, and platform fees</p>
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
              placeholder="Search transactions..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>Loading transactions...</div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Transaction ID</th>
                <th scope="col">Type</th>
                <th scope="col">User</th>
                <th scope="col">Amount</th>
                <th scope="col">Date</th>
                <th scope="col">Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No transactions match your search.' : 'No transactions found.'}
                  </td>
                </tr>
              ) : (
                filtered.map((t) => {
                  const isPositive = t.type === 'ride_payment';
                  return (
                    <tr key={t.id}>
                      <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#{t.id.slice(0, 8)}</div></td>
                      <td>{typeLabel(t.type)}</td>
                      <td>
                        <div style={{ fontWeight: 500 }}>{t.user_name}</div>
                        {t.ride_ref && <span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>{t.ride_ref}</span>}
                      </td>
                      <td style={{ fontWeight: 600, color: isPositive ? '#10b981' : '#ef4444' }}>
                        {isPositive ? '+' : '-'}${Math.abs(t.amount).toFixed(2)}
                      </td>
                      <td>
                        {new Date(t.created_at).toLocaleDateString('en-US', {
                          year: 'numeric', month: 'short', day: 'numeric',
                        })}
                      </td>
                      <td>{statusBadge(t.status)}</td>
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
