import { useEffect, useState, useMemo, useRef } from 'react';
import { 
  Search, 
  Download, 
  Send, 
  RotateCw, 
  Ticket, 
  Clock, 
  CheckCircle2, 
  AlertCircle, 
  X, 
  MessageSquare,
  ShieldCheck,
  User
} from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../context/AuthContext';
import { useToast } from '../../context/ToastContext';
import { AdminDrawer } from '../../components/ui/AdminDrawer';

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

type TicketFilterTab = 'all' | 'open' | 'in_progress' | 'resolved' | 'closed';

const statusConfig: Record<string, { label: string; className: string }> = {
  open: { label: 'Open Inquiries', className: 'admin-badge-danger' },
  in_progress: { label: 'In Progress', className: 'admin-badge-warning' },
  resolved: { label: 'Resolved', className: 'admin-badge-success' },
  closed: { label: 'Closed', className: 'admin-badge-info' },
};

const statusActions: Record<string, { label: string; next: string }[]> = {
  open: [{ label: 'Accept Ticket', next: 'in_progress' }],
  in_progress: [
    { label: 'Mark Resolved', next: 'resolved' },
    { label: 'Close Ticket', next: 'closed' },
  ],
  resolved: [{ label: 'Close Ticket', next: 'closed' }],
  closed: [{ label: 'Reopen', next: 'in_progress' }],
};

export default function SupportPage() {
  const { user } = useAuth();
  const toast = useToast();
  const [tickets, setTickets] = useState<TicketRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState<TicketFilterTab>('all');
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
      setLoading(true);
      setError(null);
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
          user_name: nameMap.get(t.user_id) || 'Unknown User',
        }))
      );
    } catch (err) {
      setError('Failed to load concierge tickets');
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
      toast.success('Concierge reply dispatched successfully');
      fetchMessages(detailTicket.id, detailTicket.user_id);
    } catch (err: any) {
      setError(err.message || 'Failed to send reply');
      toast.error(err.message || 'Failed to send reply');
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
      toast.success(`Ticket marked as ${statusConfig[newStatus]?.label || newStatus}`);
    } catch (err: any) {
      setError(err.message || 'Failed to update ticket status');
      toast.error(err.message || 'Failed to update status');
    }
  };

  const filtered = useMemo(() => {
    return tickets.filter((t) => {
      // Tab filter
      if (activeTab !== 'all' && t.status !== activeTab) return false;

      // Text search
      if (!search.trim()) return true;
      const q = search.toLowerCase();
      return (
        t.subject.toLowerCase().includes(q) ||
        t.user_name.toLowerCase().includes(q) ||
        t.id.toLowerCase().includes(q) ||
        t.description?.toLowerCase().includes(q)
      );
    });
  }, [tickets, activeTab, search]);

  const stats = useMemo(() => {
    return {
      all: tickets.length,
      open: tickets.filter((t) => t.status === 'open').length,
      in_progress: tickets.filter((t) => t.status === 'in_progress').length,
      resolved: tickets.filter((t) => ['resolved', 'closed'].includes(t.status)).length,
    };
  }, [tickets]);

  const exportCSV = () => {
    const headers = ['Ticket ID', 'Subject', 'Client / User', 'Last Updated', 'Status'];
    const rows = filtered.map((t) => [
      t.id.slice(0, 8),
      t.subject,
      t.user_name,
      new Date(t.updated_at).toLocaleString(),
      statusConfig[t.status]?.label || t.status,
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `concierge_tickets_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const timeAgo = (iso: string) => {
    const diff = Date.now() - new Date(iso).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return 'Just now';
    if (mins < 60) return `${mins}m ago`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h ago`;
    const days = Math.floor(hrs / 24);
    return `${days}d ago`;
  };

  const shortId = (id: string) => id.slice(0, 8);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Page Header */}
      <div className="admin-page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1>Concierge Desk</h1>
          <p>Clientele inquiries, chauffeur communications, and executive assistance tickets</p>
        </div>
        <div className="admin-page-header-actions">
          <button className="admin-btn admin-btn-outline" onClick={fetchTickets} title="Refresh inquiries">
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
            <span className="admin-kpi-label">Active Support Queue</span>
            <div className="admin-kpi-value">{stats.all}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(255, 255, 255, 0.03)', color: '#fff' }}>
            <Ticket size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Open / Action Required</span>
            <div className="admin-kpi-value">{stats.open}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(239, 68, 68, 0.08)', color: 'var(--admin-danger)', borderColor: 'rgba(239, 68, 68, 0.2)' }}>
            <AlertCircle size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">In Transit & Resolution</span>
            <div className="admin-kpi-value">{stats.in_progress}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(245, 158, 11, 0.08)', color: 'var(--admin-warning)', borderColor: 'rgba(245, 158, 11, 0.2)' }}>
            <Clock size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Settled / Closed</span>
            <div className="admin-kpi-value">{stats.resolved}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(16, 185, 129, 0.08)', color: 'var(--admin-success)', borderColor: 'rgba(16, 185, 129, 0.2)' }}>
            <CheckCircle2 size={18} />
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
                All Inquiries <span className="admin-filter-count">{stats.all}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'open' ? 'active' : ''}`}
                onClick={() => setActiveTab('open')}
              >
                Open <span className="admin-filter-count">{stats.open}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'in_progress' ? 'active' : ''}`}
                onClick={() => setActiveTab('in_progress')}
              >
                In Progress <span className="admin-filter-count">{stats.in_progress}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'resolved' ? 'active' : ''}`}
                onClick={() => setActiveTab('resolved')}
              >
                Resolved
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'closed' ? 'active' : ''}`}
                onClick={() => setActiveTab('closed')}
              >
                Closed
              </button>
            </div>

            {/* Search Box */}
            <div className="admin-search-wrapper" style={{ minWidth: 260 }}>
              <Search size={15} style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)', color: '#71717a' }} />
              <input
                type="text"
                placeholder="Search ticket, subject, client..."
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
            Loading concierge desk communications...
          </div>
        ) : error ? (
          <div style={{ padding: '3.5rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem', fontSize: '0.9rem' }}>{error}</p>
            <button className="admin-btn" onClick={fetchTickets}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col" style={{ width: '120px' }}>Ticket Code</th>
                <th scope="col">Inquiry Subject</th>
                <th scope="col">Client / Account</th>
                <th scope="col" style={{ width: '130px' }}>Activity</th>
                <th scope="col" style={{ width: '140px' }}>Standing</th>
                <th scope="col" style={{ width: '150px', textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '3.5rem 1rem', color: '#71717a' }}>
                    {search ? 'No inquiries match your search filter.' : 'All concierge assistance tickets are resolved.'}
                  </td>
                </tr>
              ) : (
                filtered.map((t) => (
                  <tr key={t.id} style={{ cursor: 'pointer' }} onClick={() => setDetailTicket(t)}>
                    <td data-label="Ticket Code">
                      <div style={{ fontFamily: 'monospace', color: '#a1a1aa', fontSize: '0.82rem' }}>
                        #{shortId(t.id)}
                      </div>
                    </td>
                    <td data-label="Inquiry Subject">
                      <div style={{ fontWeight: 600, color: '#fff', fontSize: '0.85rem' }}>{t.subject}</div>
                      {t.description && (
                        <div style={{ fontSize: '0.72rem', color: '#71717a', maxWidth: '340px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', marginTop: 2 }}>
                          {t.description}
                        </div>
                      )}
                    </td>
                    <td data-label="Client / Account">
                      <div className="admin-table-user-cell">
                        <div className="admin-avatar-small">
                          {t.user_name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div style={{ fontWeight: 500, color: '#e4e4e7', fontSize: '0.84rem' }}>{t.user_name}</div>
                        </div>
                      </div>
                    </td>
                    <td data-label="Activity">
                      <span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>
                        {timeAgo(t.updated_at)}
                      </span>
                    </td>
                    <td data-label="Standing">
                      <span className={`admin-badge ${statusConfig[t.status]?.className || ''}`}>
                        {statusConfig[t.status]?.label || t.status}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '0.4rem' }} onClick={(e) => e.stopPropagation()}>
                        <button
                          className="admin-btn admin-btn-outline"
                          style={{ padding: '0.35rem 0.65rem', fontSize: '0.75rem' }}
                          onClick={() => setDetailTicket(t)}
                        >
                          Inspect
                        </button>
                        {(statusActions[t.status] || []).map((action) => (
                          <button
                            key={action.next}
                            className="admin-btn"
                            style={{ padding: '0.35rem 0.65rem', fontSize: '0.75rem' }}
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

      {/* Ticket Detail & Live Thread Slide-Over Drawer (Zero Modal) */}
      <AdminDrawer
        isOpen={!!detailTicket}
        onClose={() => setDetailTicket(null)}
        width={580}
        title={detailTicket?.subject || ''}
        subtitle={detailTicket ? `#${shortId(detailTicket.id)} · Client: ${detailTicket.user_name} · Last active ${timeAgo(detailTicket.updated_at)}` : ''}
        headerAction={detailTicket ? (
          <span className={`admin-badge ${statusConfig[detailTicket.status]?.className || ''}`}>
            {statusConfig[detailTicket.status]?.label || detailTicket.status}
          </span>
        ) : undefined}
        footer={
          <button className="admin-btn admin-btn-outline" onClick={() => setDetailTicket(null)}>
            Close Drawer
          </button>
        }
      >
        {detailTicket && (
          <>
            {/* Quick Status Workflow Action Bar */}
            {(statusActions[detailTicket.status] || []).length > 0 && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.75rem', paddingBottom: '0.75rem', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                <span style={{ fontSize: '0.72rem', color: '#71717a', fontWeight: 600, textTransform: 'uppercase' }}>
                  Workflow:
                </span>
                {(statusActions[detailTicket.status] || []).map((action) => (
                  <button
                    key={action.next}
                    className="admin-btn"
                    style={{ padding: '0.3rem 0.75rem', fontSize: '0.75rem' }}
                    onClick={() => handleStatusChange(detailTicket.id, action.next)}
                  >
                    {action.label}
                  </button>
                ))}
              </div>
            )}

            {/* Initial Request Description */}
            {detailTicket.description && (
              <div style={{ background: '#16161a', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '0.85rem', marginBottom: '0.75rem' }}>
                <span style={{ fontSize: '0.68rem', fontWeight: 700, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em', display: 'block', marginBottom: 4 }}>
                  Initial Client Request
                </span>
                <p style={{ margin: 0, fontSize: '0.84rem', color: '#e4e4e7', lineHeight: 1.5 }}>
                  {detailTicket.description}
                </p>
              </div>
            )}

            {/* Messages Thread Container */}
            <div className="concierge-thread-container" style={{ minHeight: 280, maxHeight: 420 }}>
              {messagesLoading ? (
                <div style={{ textAlign: 'center', color: '#71717a', padding: '2.5rem' }}>
                  <RotateCw size={20} className="admin-spin" style={{ margin: '0 auto 0.5rem', display: 'block' }} />
                  Loading conversation telemetry...
                </div>
              ) : messages.length === 0 ? (
                <div style={{ textAlign: 'center', color: '#71717a', padding: '2.5rem' }}>
                  <MessageSquare size={28} style={{ margin: '0 auto 0.5rem', display: 'block', opacity: 0.4 }} />
                  No prior correspondence on this ticket.
                </div>
              ) : (
                messages.map((m) => (
                  <div
                    key={m.id}
                    className={`concierge-bubble ${m.is_admin ? 'concierge-bubble-admin' : 'concierge-bubble-user'}`}
                  >
                    <div className={`concierge-bubble-sender ${m.is_admin ? 'admin' : 'user'}`}>
                      {m.is_admin ? <ShieldCheck size={13} /> : <User size={13} />}
                      {m.is_admin ? 'Executive Concierge' : m.sender_name}
                    </div>
                    <div style={{ whiteSpace: 'pre-wrap' }}>{m.message}</div>
                    <div className="concierge-bubble-time">{timeAgo(m.created_at)}</div>
                  </div>
                ))
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Reply Input Box */}
            {detailTicket.status !== 'closed' ? (
              <div className="concierge-reply-box" style={{ marginTop: '0.75rem' }}>
                <input
                  className="admin-input"
                  placeholder="Type executive concierge reply..."
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                      e.preventDefault();
                      handleSendReply();
                    }
                  }}
                  disabled={sending}
                  style={{ flex: 1 }}
                />
                <button
                  className="admin-btn"
                  onClick={handleSendReply}
                  disabled={!replyText.trim() || sending}
                  style={{ padding: '0.55rem 1rem' }}
                >
                  <Send size={14} style={{ marginRight: 4 }} /> Send
                </button>
              </div>
            ) : (
              <div style={{ textAlign: 'center', padding: '0.75rem', marginTop: '0.75rem', background: 'rgba(255,255,255,0.02)', borderRadius: 8, fontSize: '0.78rem', color: '#71717a' }}>
                This ticket has been marked as closed. Reopen above to send additional replies.
              </div>
            )}
          </>
        )}
      </AdminDrawer>

    </div>
  );
}
