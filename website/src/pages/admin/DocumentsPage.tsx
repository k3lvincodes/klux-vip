import { useEffect, useState, useMemo } from 'react';
import { Search, Download, Eye, CheckCircle, XCircle } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface DocRow {
  id: string;
  driver_id: string;
  type: string;
  status: string;
  expires_at: string | null;
  created_at: string;
  driver_name: string;
}

export default function DocumentsPage() {
  const [docs, setDocs] = useState<DocRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchDocuments();
  }, []);

  const fetchDocuments = async () => {
    try {
      const { data, error } = await supabase
        .from('driver_documents')
        .select('id, driver_id, type, status, expires_at, created_at')
        .order('created_at', { ascending: false })
        .limit(100);

      if (error) throw error;

      const ids = [...new Set(data?.map((d) => d.driver_id) || [])];
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .in('id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']);

      const nameMap = new Map<string, string>();
      profiles?.forEach((p) => {
        nameMap.set(p.id, [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email);
      });

      setDocs(
        (data || []).map((d) => ({
          id: d.id,
          driver_id: d.driver_id,
          type: d.type,
          status: d.status,
          expires_at: d.expires_at,
          created_at: d.created_at,
          driver_name: nameMap.get(d.driver_id) || 'Unknown',
        }))
      );
    } catch (err) {
      console.error('Error fetching documents:', err);
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    if (!search.trim()) return docs;
    const q = search.toLowerCase();
    return docs.filter((d) => d.driver_name.toLowerCase().includes(q));
  }, [docs, search]);

  const exportCSV = () => {
    const headers = ['Chauffeur', 'Document Type', 'Submitted', 'Expiry', 'Status'];
    const rows = filtered.map((d) => [
      d.driver_name,
      typeLabel(d.type),
      new Date(d.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }),
      d.expires_at
        ? new Date(d.expires_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
        : '--',
      statusLabel(d.status),
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `documents_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const typeLabel = (type: string) => {
    switch (type) {
      case 'driver_license': return "Chauffeur's License";
      case 'insurance': return 'Vehicle Insurance';
      case 'registration': return 'Vehicle Registration';
      case 'background_check': return 'Background Check';
      default: return type;
    }
  };

  const statusBadge = (status: string) => {
    switch (status) {
      case 'approved':
        return <span className="admin-badge admin-badge-success">Verified</span>;
      case 'rejected':
        return <span className="admin-badge admin-badge-danger">Rejected</span>;
      case 'pending':
      default:
        return <span className="admin-badge admin-badge-warning">Pending Review</span>;
    }
  };

  const statusLabel = (s: string) => {
    switch (s) {
      case 'approved': return 'Verified';
      case 'rejected': return 'Rejected';
      case 'pending': default: return 'Pending Review';
    }
  };

  const formatDate = (iso: string | null) => {
    if (!iso) return '--';
    return new Date(iso).toLocaleDateString('en-US', {
      year: 'numeric', month: 'short', day: 'numeric',
    });
  };

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Document Verification</h1>
          <p>Review and approve chauffeur licenses, insurance, and background checks</p>
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
              placeholder="Search by chauffeur name..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>Loading documents...</div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Chauffeur</th>
                <th scope="col">Document Type</th>
                <th scope="col">Submitted</th>
                <th scope="col">Expiry</th>
                <th scope="col">Status</th>
                <th scope="col">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No documents match your search.' : 'No documents found.'}
                  </td>
                </tr>
              ) : (
                filtered.map((d) => (
                  <tr key={d.id}>
                    <td><div style={{ fontWeight: 500 }}>{d.driver_name}</div></td>
                    <td>{typeLabel(d.type)}</td>
                    <td>{formatDate(d.created_at)}</td>
                    <td>{formatDate(d.expires_at)}</td>
                    <td>{statusBadge(d.status)}</td>
                    <td>
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        <button className="admin-btn admin-btn-outline" style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem' }}>
                          <Eye size={14} />
                        </button>
                        {d.status === 'pending' && (
                          <>
                            <button style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem', background: 'var(--admin-success-dim)', color: 'var(--admin-success)', border: '1px solid rgba(16,185,129,0.2)', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center' }}>
                              <CheckCircle size={14} />
                            </button>
                            <button style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem', background: 'var(--admin-danger-dim)', color: 'var(--admin-danger)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center' }}>
                              <XCircle size={14} />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
