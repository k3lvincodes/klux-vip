import { useEffect, useState, useMemo } from 'react';
import { Search, Download, MessageSquare } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface TicketRow {
  id: string;
  subject: string;
  description: string;
  status: string;
  created_at: string;
  updated_at: string;
  user_name: string;
}

export default function SupportPage() {
  const [tickets, setTickets] = useState<TicketRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [detailTicket, setDetailTicket] = useState<TicketRow | null>(null);

  useEffect(() => {
    fetchTickets();
  }, []);

  const fetchTickets = async () => {
    try {
      const { data, error } = await supabase
        .from('support_tickets')
        .select('id, user_id, subject, description, status, created_at, updated_at')
        .order('updated_at', { ascending: false })
        .limit(100);

      if (error) throw error;

      const ids = [...new Set(data?.map((t) => t.user_id) || [])];
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .in('id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']);

      const nameMap = new Map<string, string>();
      profiles?.forEach((p) => {
        nameMap.set(p.id, [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email);
      });

      setTickets(
        (data || []).map((t) => ({
          id: t.id,
          subject: t.subject,
          description: t.description,
          status: t.status,
          created_at: t.created_at,
          updated_at: t.updated_at,
          user_name: nameMap.get(t.user_id) || 'Unknown',
        }))
      );
    } catch (err) {
      setError('Failed to load tickets');
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    if (!search.trim()) return tickets;
    const q = search.toLowerCase();
    return tickets.filter(
      (t) =>
        t.subject.toLowerCase().includes(q) ||
        t.user_name.toLowerCase().includes(q) ||
        t.id.toLowerCase().includes(q)
    );
  }, [tickets, search]);

  const exportCSV = () => {
    const headers = ['Ticket ID', 'Subject', 'User', 'Last Updated', 'Status'];
    const rows = filtered.map((t) => [
      t.id.slice(0, 8),
      t.subject,
      t.user_name,
      timeAgo(t.updated_at),
      statusLabel(t.status),
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `support_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const timeAgo = (iso: string) => {
    const diff = Date.now() - new Date(iso).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins} min${mins !== 1 ? 's' : ''} ago`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs} hour${hrs !== 1 ? 's' : ''} ago`;
    const days = Math.floor(hrs / 24);
    return `${days} day${days !== 1 ? 's' : ''} ago`;
  };

  const statusBadge = (status: string) => {
    switch (status) {
      case 'open':
        return <span className="admin-badge admin-badge-danger">Open</span>;
      case 'in_progress':
        return <span className="admin-badge admin-badge-warning">Pending</span>;
      case 'resolved':
      case 'closed':
        return <span className="admin-badge admin-badge-success">Resolved</span>;
      default:
        return <span className="admin-badge">{status}</span>;
    }
  };

  const statusLabel = (status: string) => {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'Pending';
      case 'resolved': case 'closed': return 'Resolved';
      default: return status;
    }
  };

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Support Desk</h1>
          <p>Customer and chauffeur support tickets</p>
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
              placeholder="Search tickets..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>Loading tickets...</div>
        ) : error ? (
          <div style={{ padding: '3rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error}</p>
            <button className="admin-btn" onClick={() => { setError(null); setLoading(true); fetchTickets(); }}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Ticket ID</th>
                <th scope="col">Subject</th>
                <th scope="col">User</th>
                <th scope="col">Last Updated</th>
                <th scope="col">Status</th>
                <th scope="col">Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No tickets match your search.' : 'No tickets found.'}
                  </td>
                </tr>
              ) : (
                filtered.map((t) => (
                  <tr key={t.id}>
                    <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#{t.id.slice(0, 8)}</div></td>
                    <td><div style={{ fontWeight: 500 }}>{t.subject}</div></td>
                    <td>{t.user_name}</td>
                    <td>{timeAgo(t.updated_at)}</td>
                    <td>{statusBadge(t.status)}</td>
                    <td>
                      <button
                        className="admin-btn admin-btn-outline"
                        style={{ padding: '0.4rem 0.8rem', fontSize: '0.8rem', cursor: 'pointer' }}
                        onClick={() => setDetailTicket(t)}
                      >
                        <MessageSquare size={14} /> View
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>

      {detailTicket && (
        <div
          style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.7)', zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center', backdropFilter: 'blur(4px)' }}
          onClick={(e) => { if (e.target === e.currentTarget) setDetailTicket(null); }}
        >
          <div style={{ background: '#18181b', borderRadius: '16px', padding: '2rem', maxWidth: '500px', width: '90%', maxHeight: '80vh', overflowY: 'auto', border: '1px solid rgba(255,255,255,0.1)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h3 style={{ color: '#fff', fontSize: '18px', fontWeight: 700, margin: 0 }}>{detailTicket.subject}</h3>
              <button onClick={() => setDetailTicket(null)} style={{ background: 'none', border: 'none', color: '#a1a1aa', cursor: 'pointer', fontSize: '20px', padding: '4px' }}>&times;</button>
            </div>
            <p style={{ color: '#a1a1aa', fontSize: '13px', margin: '0 0 0.5rem' }}>From: {detailTicket.user_name}</p>
            <p style={{ color: '#71717a', fontSize: '12px', margin: '0 0 1rem' }}>Ticket #{detailTicket.id.slice(0,8)} &bull; {timeAgo(detailTicket.updated_at)}</p>
            <div style={{ color: '#e4e4e7', fontSize: '14px', lineHeight: 1.6, whiteSpace: 'pre-wrap' }}>{detailTicket.description}</div>
          </div>
        </div>
      )}
    </div>
  );
}
