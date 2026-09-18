import { useEffect, useState, useMemo } from 'react';
import { 
  Search, 
  Download, 
  WalletCards, 
  CheckCircle2, 
  Clock, 
  AlertCircle, 
  ArrowUpRight, 
  ArrowDownLeft, 
  RotateCw,
  X,
  Eye,
  CircleDollarSign,
  Calendar,
  User,
  MapPin
} from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
import { AdminDrawer } from '../../components/ui/AdminDrawer';

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

type LedgerFilterTab = 'all' | 'payments' | 'payouts' | 'settled' | 'pending' | 'failed';

export default function TransactionsPage() {
  const toast = useToast();
  const [transactions, setTransactions] = useState<TransactionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState<LedgerFilterTab>('all');
  const [selectedTx, setSelectedTx] = useState<TransactionRow | null>(null);

  useEffect(() => {
    fetchTransactions();
  }, []);

  const fetchTransactions = async () => {
    try {
      setLoading(true);
      setError(null);
      const { data, error } = await supabase
        .from('transactions')
        .select('id, user_id, ride_id, amount, type, status, created_at')
        .order('created_at', { ascending: false })
        .limit(150);

      if (error) throw error;

      const userIds = [...new Set(data?.map((t) => t.user_id) || [])];

      const profileRes = await supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .in('id', userIds.length > 0 ? userIds : ['00000000-0000-0000-0000-000000000000']);


      const nameMap = new Map<string, string>();
      profileRes.data?.forEach((p) => {
        nameMap.set(p.id, [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email);
      });

      setTransactions(
        (data || []).map((t) => ({
          id: t.id,
          user_id: t.user_id,
          ride_id: t.ride_id,
          amount: Number(t.amount),
          type: t.type,
          status: t.status,
          created_at: t.created_at,
          user_name: nameMap.get(t.user_id) || 'Unknown User',
          ride_ref: t.ride_id ? `Ride #${t.ride_id.slice(0, 8)}` : null,
        }))
      );
    } catch (err) {
      setError('Failed to load financial ledger');
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    return transactions.filter((t) => {
      // Tab filter
      if (activeTab === 'payments' && t.type !== 'ride_payment') return false;
      if (activeTab === 'payouts' && t.type !== 'withdrawal') return false;
      if (activeTab === 'settled' && t.status !== 'completed') return false;
      if (activeTab === 'pending' && t.status !== 'pending') return false;
      if (activeTab === 'failed' && t.status !== 'failed') return false;

      // Text search
      if (!search.trim()) return true;
      const q = search.toLowerCase();
      return (
        t.user_name.toLowerCase().includes(q) ||
        typeLabel(t.type).toLowerCase().includes(q) ||
        t.id.toLowerCase().includes(q) ||
        (t.ride_ref?.toLowerCase() || '').includes(q)
      );
    });
  }, [transactions, activeTab, search]);

  const tabCounts = useMemo(() => {
    return {
      all: transactions.length,
      payments: transactions.filter(t => t.type === 'ride_payment').length,
      payouts: transactions.filter(t => t.type === 'withdrawal').length,
      settled: transactions.filter(t => t.status === 'completed').length,
      pending: transactions.filter(t => t.status === 'pending').length,
      failed: transactions.filter(t => t.status === 'failed').length,
    };
  }, [transactions]);

  // Financial aggregates
  const aggregates = useMemo(() => {
    let grossPayments = 0;
    let totalPayouts = 0;
    let pendingCount = 0;

    transactions.forEach((t) => {
      if (t.status === 'completed') {
        if (t.type === 'ride_payment' || t.amount > 0) grossPayments += t.amount;
        if (t.type === 'withdrawal') totalPayouts += Math.abs(t.amount);
      }
      if (t.status === 'pending') pendingCount++;
    });

    return {
      grossPayments,
      totalPayouts,
      pendingCount,
      netRevenue: grossPayments - totalPayouts,
    };
  }, [transactions]);

  const exportCSV = () => {
    const headers = ['Entry ID', 'Type', 'Account', 'Amount ($)', 'Status', 'Timestamp', 'Linked Ref'];
    const rows = filtered.map((t) => [
      t.id.slice(0, 8),
      typeLabel(t.type),
      t.user_name,
      `${t.amount >= 0 ? '+' : '-'}${Math.abs(t.amount).toFixed(2)}`,
      statusLabel(t.status),
      new Date(t.created_at).toLocaleString(),
      t.ride_ref || '--',
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `financial_ledger_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const typeLabel = (type: string) => {
    switch (type) {
      case 'ride_payment': return 'Client Fare';
      case 'withdrawal': return 'Chauffeur Payout';
      default: return type;
    }
  };

  const statusBadge = (status: string) => {
    switch (status) {
      case 'completed':
        return <span className="admin-badge admin-badge-success"><CheckCircle2 size={11} style={{ marginRight: 3 }} /> Settled</span>;
      case 'pending':
        return <span className="admin-badge admin-badge-warning"><Clock size={11} style={{ marginRight: 3 }} /> Processing</span>;
      case 'failed':
        return <span className="admin-badge admin-badge-danger"><AlertCircle size={11} style={{ marginRight: 3 }} /> Failed</span>;
      default:
        return <span className="admin-badge">{status}</span>;
    }
  };

  const statusLabel = (s: string) => {
    switch (s) {
      case 'completed': return 'Settled';
      case 'pending': return 'Processing';
      case 'failed': return 'Failed';
      default: return s;
    }
  };

  const shortId = (id: string) => id.slice(0, 8);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Page Header */}
      <div className="admin-page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1>Financial Ledger</h1>
          <p>Real-time transaction settlement, fare collections, and chauffeur payout audit</p>
        </div>
        <div className="admin-page-header-actions">
          <button className="admin-btn admin-btn-outline" onClick={fetchTransactions} title="Refresh records">
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
            <span className="admin-kpi-label">Gross Client Fares</span>
            <div className="admin-kpi-value">${aggregates.grossPayments.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(16, 185, 129, 0.08)', color: 'var(--admin-success)', borderColor: 'rgba(16, 185, 129, 0.2)' }}>
            <ArrowDownLeft size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Chauffeur Disbursements</span>
            <div className="admin-kpi-value">${aggregates.totalPayouts.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(239, 68, 68, 0.08)', color: 'var(--admin-danger)', borderColor: 'rgba(239, 68, 68, 0.2)' }}>
            <ArrowUpRight size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Net Platform Margin</span>
            <div className="admin-kpi-value">${aggregates.netRevenue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(244, 197, 34, 0.08)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
            <CircleDollarSign size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Pending Settlements</span>
            <div className="admin-kpi-value">{aggregates.pendingCount}</div>
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
                All Entries <span className="admin-filter-count">{tabCounts.all}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'payments' ? 'active' : ''}`}
                onClick={() => setActiveTab('payments')}
              >
                Client Fares <span className="admin-filter-count">{tabCounts.payments}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'payouts' ? 'active' : ''}`}
                onClick={() => setActiveTab('payouts')}
              >
                Payouts <span className="admin-filter-count">{tabCounts.payouts}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'settled' ? 'active' : ''}`}
                onClick={() => setActiveTab('settled')}
              >
                Settled <span className="admin-filter-count">{tabCounts.settled}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'pending' ? 'active' : ''}`}
                onClick={() => setActiveTab('pending')}
              >
                Processing <span className="admin-filter-count">{tabCounts.pending}</span>
              </button>
            </div>

            {/* Search Box */}
            <div className="admin-search-wrapper" style={{ minWidth: 260 }}>
              <Search size={15} style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)', color: '#71717a' }} />
              <input
                type="text"
                placeholder="Search entry ID, user, reference..."
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
            Loading financial ledger...
          </div>
        ) : error ? (
          <div style={{ padding: '3.5rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem', fontSize: '0.9rem' }}>{error}</p>
            <button className="admin-btn" onClick={fetchTransactions}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col" style={{ width: '120px' }}>Entry ID</th>
                <th scope="col" style={{ width: '150px' }}>Transaction Type</th>
                <th scope="col">Account Participant</th>
                <th scope="col">Linked Reference</th>
                <th scope="col" style={{ width: '130px' }}>Amount</th>
                <th scope="col" style={{ width: '140px' }}>Settlement</th>
                <th scope="col" style={{ width: '60px', textAlign: 'right' }}></th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '3.5rem 1rem', color: '#71717a' }}>
                    {search ? 'No ledger entries match your search query.' : 'No financial transactions logged yet.'}
                  </td>
                </tr>
              ) : (
                filtered.map((t) => {
                  const isPositive = t.type === 'ride_payment' || t.amount > 0;
                  return (
                    <tr key={t.id} style={{ cursor: 'pointer' }} onClick={() => setSelectedTx(t)}>
                      <td data-label="Entry ID">
                        <div style={{ fontFamily: 'monospace', color: '#a1a1aa', fontSize: '0.82rem' }}>
                          #{shortId(t.id)}
                        </div>
                        <div style={{ fontSize: '0.68rem', color: '#52525b', marginTop: 2 }}>
                          {new Date(t.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}
                        </div>
                      </td>
                      <td data-label="Transaction Type">
                        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                          <span style={{ 
                            width: 22, 
                            height: 22, 
                            borderRadius: 6, 
                            display: 'flex', 
                            alignItems: 'center', 
                            justifyContent: 'center',
                            background: isPositive ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)',
                            color: isPositive ? 'var(--admin-success)' : 'var(--admin-danger)'
                          }}>
                            {isPositive ? <ArrowDownLeft size={13} /> : <ArrowUpRight size={13} />}
                          </span>
                          <span style={{ fontWeight: 600, color: '#fff', fontSize: '0.82rem' }}>{typeLabel(t.type)}</span>
                        </div>
                      </td>
                      <td data-label="Account Participant">
                        <div className="admin-table-user-cell">
                          <div className="admin-avatar-small">
                            {t.user_name.charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <div style={{ fontWeight: 600, color: '#fff', fontSize: '0.85rem' }}>{t.user_name}</div>
                            <div style={{ fontSize: '0.68rem', color: '#71717a' }}>{isPositive ? 'Client Billed' : 'Chauffeur Recipient'}</div>
                          </div>
                        </div>
                      </td>
                      <td data-label="Linked Reference">
                        {t.ride_ref ? (
                          <span style={{ fontSize: '0.78rem', color: 'var(--admin-primary)', background: 'rgba(244, 197, 34, 0.08)', padding: '2px 8px', borderRadius: 6, border: '1px solid rgba(244, 197, 34, 0.18)', fontFamily: 'monospace' }}>
                            {t.ride_ref}
                          </span>
                        ) : (
                          <span style={{ color: '#52525b', fontSize: '0.8rem', fontStyle: 'italic' }}>Direct Balance</span>
                        )}
                      </td>
                      <td data-label="Amount">
                        <span style={{ 
                          fontWeight: 700, 
                          fontSize: '0.92rem', 
                          fontVariantNumeric: 'tabular-nums',
                          color: isPositive ? 'var(--admin-success)' : '#ffffff'
                        }}>
                          {isPositive ? '+' : '-'}${Math.abs(t.amount).toFixed(2)}
                        </span>
                      </td>
                      <td data-label="Settlement">
                        {statusBadge(t.status)}
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <button 
                          className="admin-icon-btn" 
                          style={{ width: 28, height: 28 }}
                          onClick={(e) => { e.stopPropagation(); setSelectedTx(t); }}
                          title="Inspect entry"
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

      {/* Transaction Detail Slide-Over Drawer (Zero Modal) */}
      <AdminDrawer
        isOpen={!!selectedTx}
        onClose={() => setSelectedTx(null)}
        width={480}
        title={selectedTx ? `Ledger Entry #${shortId(selectedTx.id)}` : ''}
        subtitle={selectedTx ? `Recorded on ${new Date(selectedTx.created_at).toLocaleString()}` : ''}
        headerAction={selectedTx ? statusBadge(selectedTx.status) : undefined}
        footer={
          <button className="admin-btn admin-btn-outline" onClick={() => setSelectedTx(null)}>
            Done
          </button>
        }
      >
        {selectedTx && (
          <>
            {/* Amount Display */}
            <div style={{ textAlign: 'center', padding: '1.25rem', background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 12, marginBottom: '0.75rem' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                Transaction Settlement Value
              </span>
              <div style={{ 
                fontSize: '2rem', 
                fontWeight: 800, 
                fontVariantNumeric: 'tabular-nums', 
                marginTop: 6,
                color: selectedTx.type === 'ride_payment' || selectedTx.amount > 0 ? 'var(--admin-success)' : '#ffffff'
              }}>
                {selectedTx.type === 'ride_payment' || selectedTx.amount > 0 ? '+' : '-'}${Math.abs(selectedTx.amount).toFixed(2)}
              </div>
              <div style={{ fontSize: '0.78rem', color: '#a1a1aa', marginTop: 4 }}>
                {typeLabel(selectedTx.type)} · Currency USD
              </div>
            </div>

            {/* Details Rows */}
            <div style={{ background: '#0e0e11', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '1rem', display: 'flex', flexDirection: 'column', gap: 10, fontSize: '0.84rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: 8, borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                <span style={{ color: '#71717a', display: 'flex', alignItems: 'center', gap: 6 }}>
                  <User size={14} /> Participant
                </span>
                <span style={{ color: '#fff', fontWeight: 600 }}>{selectedTx.user_name}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: 8, borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                <span style={{ color: '#71717a', display: 'flex', alignItems: 'center', gap: 6 }}>
                  <WalletCards size={14} /> Operation Classification
                </span>
                <span style={{ color: '#fff' }}>{typeLabel(selectedTx.type)}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: 8, borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                <span style={{ color: '#71717a', display: 'flex', alignItems: 'center', gap: 6 }}>
                  <MapPin size={14} /> Linked Journey Reference
                </span>
                {selectedTx.ride_ref ? (
                  <button
                    type="button"
                    onClick={() => {
                      navigator.clipboard.writeText(selectedTx.ride_ref!);
                      toast.success('Journey ID copied to clipboard');
                    }}
                    style={{ background: 'none', border: 'none', color: 'var(--admin-primary)', fontFamily: 'monospace', cursor: 'pointer', padding: 0, textDecoration: 'underline' }}
                    title="Click to copy journey reference"
                  >
                    {selectedTx.ride_ref}
                  </button>
                ) : (
                  <span style={{ color: '#71717a' }}>Direct Platform Settlement</span>
                )}
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: '#71717a', display: 'flex', alignItems: 'center', gap: 6 }}>
                  <Calendar size={14} /> Timestamp
                </span>
                <span style={{ color: '#e4e4e7' }}>
                  {new Date(selectedTx.created_at).toLocaleString()}
                </span>
              </div>
            </div>
          </>
        )}
      </AdminDrawer>

    </div>
  );
}
