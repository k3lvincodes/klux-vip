import { useEffect, useState, useMemo, useRef } from 'react';
import { Search, Download, Send } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../context/AuthContext';

interface TicketRow {
  id: string;
  subject: string;
  description: string;
  status: string;
  created_at: string;
  updated_at: string;
  user_name: string;
  user_id: string;
}

interface TicketMessage {
  id: string;
  ticket_id: string;
  sender_id: string;
  message: string;
  created_at: string;
  sender_name: string;
  is_admin: boolean;
}

const statusConfig: Record<string, { label: string; className: string }> = {
  open: { label: 'Open', className: 'admin-badge-danger' },
  in_progress: { label: 'In Progress', className: 'admin-badge-warning' },
  resolved: { label: 'Resolved', className: 'admin-badge-success' },
  closed: { label: 'Closed', className: 'admin-badge-info' },
};

const statusActions: Record<string, { label: string; next: string }[]> = {
  open: [{ label: 'Start', next: 'in_progress' }],
  in_progress: [
    { label: 'Resolve', next: 'resolved' },
    { label: 'Close', next: 'closed' },
  ],
  resolved: [{ label: 'Close', next: 'closed' }],
  closed: [],
};

export default function SupportPage() {
  const { user } = useAuth();
  const [tickets, setTickets] = useState<TicketRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [detailTicket, setDetailTicket] = useState<TicketRow | null>(null);
  const [messages, setMessages] = useState<TicketMessage[]>([]);
  const [messagesLoading, setMessagesLoading] = useState(false);
  const [replyText, setReplyText] = useState('');
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchTickets();
  }, []);

  useEffect(() => {
    if (detailTicket) {
      fetchMessages(detailTicket.id, detailTicket.user_id);
    }
  }, [detailTicket?.id]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

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
          ...t,
          user_name: nameMap.get(t.user_id) || 'Unknown',
        }))
      );
    } catch (err) {
      setError('Failed to load tickets');
    } finally {
      setLoading(false);
    }
  };

  const fetchMessages = async (ticketId: string, userId: string) => {
    setMessagesLoading(true);
    try {
      const { data, error } = await supabase
        .from('ticket_messages')
        .select('id, ticket_id, sender_id, message, created_at')
        .eq('ticket_id', ticketId)
        .order('created_at', { ascending: true });

      if (error) throw error;

      const senderIds = [...new Set((data || []).map((m) => m.sender_id))];
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .in('id', senderIds.length > 0 ? senderIds : ['00000000-0000-0000-0000-000000000000']);

      const nameMap = new Map<string, string>();
      profiles?.forEach((p) => {
        nameMap.set(p.id, [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email);
      });

      setMessages(
        (data || []).map((m) => ({
          ...m,
          sender_name: nameMap.get(m.sender_id) || 'Unknown',
          is_admin: m.sender_id !== userId,
        }))
      );
    } catch (err) {
      setError('Failed to load messages');
    } finally {
      setMessagesLoading(false);
    }
  };

  const handleSendReply = async () => {
    if (!replyText.trim() || !detailTicket || !user) return;
    setSending(true);
    try {
      const { error } = await supabase
        .from('ticket_messages')
        .insert({
          ticket_id: detailTicket.id,
          sender_id: user.id,
          message: replyText.trim(),
        });
      if (error) throw error;

      await supabase
        .from('support_tickets')
        .update({ updated_at: new Date().toISOString() })
        .eq('id', detailTicket.id);

      setReplyText('');
      fetchMessages(detailTicket.id, detailTicket.user_id);
    } catch (err: any) {
      setError(err.message || 'Failed to send reply');
    } finally {
      setSending(false);
    }
  };

  const handleStatusChange = async (ticketId: string, newStatus: string) => {
    try {
      const { error } = await supabase
        .from('support_tickets')
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .eq('id', ticketId);
      if (error) throw error;

      setTickets((prev) =>
        prev.map((t) => (t.id === ticketId ? { ...t, status: newStatus } : t))
      );
      if (detailTicket?.id === ticketId) {
        setDetailTicket((prev) => (prev ? { ...prev, status: newStatus } : null));
      }
    } catch (err: any) {
      setError(err.message || 'Failed to update status');
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
      statusConfig[t.status]?.label || t.status,
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
    if (mins < 1) return 'Just now';
    if (mins < 60) return `${mins} min${mins !== 1 ? 's' : ''} ago`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs} hour${hrs !== 1 ? 's' : ''} ago`;
    const days = Math.floor(hrs / 24);
    return `${days} day${days !== 1 ? 's' : ''} ago`;
  };

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Support Desk</h1>
          <p>Customer and chauffeur support tickets</p>
        </div>
        <div className="admin-page-header-actions">
          <button className="admin-btn" onClick={exportCSV}>
            <Download size={16} />
            Export CSV
          </button>
        </div>
      </div>

      <div className="admin-table-wrapper">
        <div className="admin-table-filter-bar">
          <div className="admin-search-wrapper">
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input
              type="text"
              placeholder="Search tickets..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="admin-search-input"
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
                <th scope="col">Actions</th>
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
                    <td data-label="Ticket ID"><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#{t.id.slice(0, 8)}</div></td>
                    <td data-label="Subject"><div style={{ fontWeight: 500 }}>{t.subject}</div></td>
                    <td data-label="User">{t.user_name}</td>
                    <td data-label="Last Updated">{timeAgo(t.updated_at)}</td>
                    <td data-label="Status">
                      <span className={`admin-badge ${statusConfig[t.status]?.className || ''}`}>
                        {statusConfig[t.status]?.label || t.status}
                      </span>
                    </td>
                    <td data-label="Actions">
                      <div style={{ display: 'flex', gap: '0.4rem' }}>
                        <button
                          className="admin-btn admin-btn-outline"
                          style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem' }}
                          onClick={() => setDetailTicket(t)}
                        >
                          View
                        </button>
                        {(statusActions[t.status] || []).map((action) => (
                          <button
                            key={action.next}
                            className="admin-btn"
                            style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem' }}
                            onClick={() => handleStatusChange(t.id, action.next)}
                          >
                            {action.label}
                          </button>
                        ))}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>

      {/* Ticket Detail Modal */}
      {detailTicket && (
        <div
          className="admin-modal-overlay"
          style={{ zIndex: 9999 }}
          onClick={(e) => { if (e.target === e.currentTarget) setDetailTicket(null); }}
        >
          <div className="admin-modal" style={{ maxWidth: '560px', width: '90%', maxHeight: '85vh', display: 'flex', flexDirection: 'column' }}>
            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.75rem', flexShrink: 0 }}>
              <div>
                <h3 style={{ color: '#fff', fontSize: '16px', fontWeight: 700, margin: 0 }}>{detailTicket.subject}</h3>
                <p style={{ color: '#71717a', fontSize: '12px', margin: '4px 0 0' }}>
                  #{detailTicket.id.slice(0, 8)} &bull; {detailTicket.user_name} &bull; {timeAgo(detailTicket.updated_at)}
                </p>
              </div>
              <button onClick={() => setDetailTicket(null)} style={{ background: 'none', border: 'none', color: '#a1a1aa', cursor: 'pointer', fontSize: '20px', padding: '4px' }}>&times;</button>
            </div>

            {/* Status Actions */}
            {(statusActions[detailTicket.status] || []).length > 0 && (
              <div style={{ display: 'flex', gap: '0.4rem', marginBottom: '0.75rem', flexShrink: 0 }}>
                {(statusActions[detailTicket.status] || []).map((action) => (
                  <button
                    key={action.next}
                    className="admin-btn"
                    style={{ padding: '0.3rem 0.7rem', fontSize: '0.75rem' }}
                    onClick={() => handleStatusChange(detailTicket.id, action.next)}
                  >
                    {action.label}
                  </button>
                ))}
              </div>
            )}

            {/* Messages */}
            <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '0.75rem', minHeight: 0, padding: '0.5rem 0' }}>
              {messagesLoading ? (
                <div style={{ textAlign: 'center', color: '#71717a', padding: '2rem' }}>Loading messages...</div>
              ) : messages.length === 0 ? (
                <div style={{ textAlign: 'center', color: '#71717a', padding: '2rem' }}>No messages yet.</div>
              ) : (
                messages.map((m) => (
                  <div
                    key={m.id}
                    style={{
                      alignSelf: m.is_admin ? 'flex-end' : 'flex-start',
                      maxWidth: '80%',
                    }}
                  >
                    <div
                      style={{
                        padding: '0.6rem 0.85rem',
                        borderRadius: m.is_admin ? '12px 12px 2px 12px' : '12px 12px 12px 2px',
                        background: m.is_admin ? 'rgba(234,179,8,0.15)' : 'rgba(255,255,255,0.06)',
                        border: m.is_admin ? '1px solid rgba(234,179,8,0.2)' : '1px solid rgba(255,255,255,0.08)',
                      }}
                    >
                      <p style={{ fontSize: '11px', color: '#a1a1aa', margin: '0 0 4px', fontWeight: 600 }}>
                        {m.is_admin ? 'Admin' : m.sender_name}
                      </p>
                      <p style={{ fontSize: '13px', color: '#e4e4e7', margin: 0, whiteSpace: 'pre-wrap', lineHeight: 1.5 }}>{m.message}</p>
                    </div>
                    <p style={{ fontSize: '10px', color: '#52525b', margin: '2px 0 0', textAlign: m.is_admin ? 'right' : 'left' }}>{timeAgo(m.created_at)}</p>
                  </div>
                ))
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Reply Input */}
            {detailTicket.status !== 'closed' && (
              <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.75rem', borderTop: '1px solid rgba(255,255,255,0.08)', paddingTop: '0.75rem', flexShrink: 0 }}>
                <input
                  className="admin-input"
                  placeholder="Type your reply..."
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSendReply(); } }}
                  disabled={sending}
                  style={{ flex: 1 }}
                />
                <button
                  className="admin-btn"
                  onClick={handleSendReply}
                  disabled={!replyText.trim() || sending}
                  style={{ padding: '0.5rem 0.8rem' }}
                >
                  <Send size={14} />
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
