import { useEffect, useState, useMemo } from 'react';
import {
  Search,
  Download,
  Eye,
  CheckCircle,
  XCircle,
  ChevronDown,
  Loader2,
  Clock,
  ShieldCheck,
  ShieldAlert,
  Users,
} from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface Doc {
  id: string;
  driver_id: string;
  type: string;
  status: string;
  file_url: string;
  rejection_reason: string | null;
  expires_at: string | null;
  created_at: string;
}

interface DriverGroup {
  driver_id: string;
  driver_name: string;
  docs: Doc[];
  expanded: boolean;
}

export default function DocumentsPage() {
  const [groups, setGroups] = useState<DriverGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [previewDoc, setPreviewDoc] = useState<Doc | null>(null);
  const [diditData, setDiditData] = useState<any>(null);
  const [diditLoading, setDiditLoading] = useState(false);
  const [diditError, setDiditError] = useState('');
  const [rejectModal, setRejectModal] = useState<{ open: boolean; docId: string | null }>({ open: false, docId: null });
  const [rejectReason, setRejectReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    fetchDocuments();
  }, []);

  const fetchDocuments = async () => {
    try {
      const { data: docs, error } = await supabase
        .from('driver_documents')
        .select('id, driver_id, type, status, file_url, rejection_reason, expires_at, created_at')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const ids = [...new Set(docs?.map((d) => d.driver_id) || [])];
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .in('id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']);

      const nameMap = new Map<string, string>();
      profiles?.forEach((p) => {
        nameMap.set(p.id, [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email);
      });

      const grouped = new Map<string, Doc[]>();
      (docs || []).forEach((d) => {
        const key = d.driver_id;
        if (!grouped.has(key)) grouped.set(key, []);
        grouped.get(key)!.push({
          id: d.id,
          driver_id: d.driver_id,
          type: d.type,
          status: d.status,
          file_url: d.file_url,
          rejection_reason: d.rejection_reason,
          expires_at: d.expires_at,
          created_at: d.created_at,
        });
      });

      setGroups(
        [...grouped.entries()].map(([driver_id, docs]) => ({
          driver_id,
          driver_name: nameMap.get(driver_id) || 'Unknown Chauffeur',
          docs,
          expanded: false,
        }))
      );
    } catch (err) {
      setError('Failed to load document records');
    } finally {
      setLoading(false);
    }
  };

  // Stats computation
  const stats = useMemo(() => {
    let totalDocs = 0;
    let pending = 0;
    let approved = 0;
    let rejected = 0;

    groups.forEach((g) => {
      g.docs.forEach((d) => {
        totalDocs++;
        if (d.status === 'pending') pending++;
        else if (d.status === 'approved') approved++;
        else if (d.status === 'rejected') rejected++;
      });
    });

    return {
      chauffeurs: groups.length,
      totalDocs,
      pending,
      approved,
      rejected,
    };
  }, [groups]);

  // Filtering by search and tab
  const filtered = useMemo(() => {
    return groups
      .map((g) => {
        const matchesSearch = !search.trim() || g.driver_name.toLowerCase().includes(search.toLowerCase());
        if (!matchesSearch) return null;

        if (statusFilter === 'all') return g;

        const matchingDocs = g.docs.filter((d) => d.status === statusFilter);
        if (matchingDocs.length === 0) return null;

        return {
          ...g,
          docs: matchingDocs,
        };
      })
      .filter(Boolean) as DriverGroup[];
  }, [groups, search, statusFilter]);

  const toggleExpand = (driver_id: string) => {
    setGroups((prev) =>
      prev.map((g) => (g.driver_id === driver_id ? { ...g, expanded: !g.expanded } : g))
    );
  };

  const expandAll = () => {
    setGroups((prev) => prev.map((g) => ({ ...g, expanded: true })));
  };

  const collapseAll = () => {
    setGroups((prev) => prev.map((g) => ({ ...g, expanded: false })));
  };

  const handleApprove = async (docId: string) => {
    setActionLoading(true);
    try {
      const { error } = await supabase
        .from('driver_documents')
        .update({ status: 'approved', updated_at: new Date().toISOString() })
        .eq('id', docId);

      if (error) return;

      setGroups((prev) =>
        prev.map((g) => ({
          ...g,
          docs: g.docs.map((d) => (d.id === docId ? { ...d, status: 'approved' } : d)),
        }))
      );
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = (docId: string) => {
    setRejectModal({ open: true, docId });
    setRejectReason('');
  };

  const confirmReject = async () => {
    if (!rejectModal.docId) return;
    setActionLoading(true);
    try {
      const reason = rejectReason.trim();

      const { error } = await supabase
        .from('driver_documents')
        .update({ status: 'rejected', rejection_reason: reason || null, updated_at: new Date().toISOString() })
        .eq('id', rejectModal.docId);

      if (error) {
        setRejectModal({ open: false, docId: null });
        return;
      }

      setGroups((prev) =>
        prev.map((g) => ({
          ...g,
          docs: g.docs.map((d) =>
            d.id === rejectModal.docId ? { ...d, status: 'rejected', rejection_reason: reason || null } : d
          ),
        }))
      );
      setRejectModal({ open: false, docId: null });
    } finally {
      setActionLoading(false);
    }
  };

  const typeLabel = (type: string) => {
    switch (type) {
      case 'driver_license':
        return "Chauffeur's License";
      case 'insurance':
        return 'Vehicle Insurance';
      case 'registration':
        return 'Vehicle Registration';
      case 'background_check':
        return 'Background Security Check';
      default:
        return type.replace(/_/g, ' ');
    }
  };

  const statusBadge = (status: string) => {
    switch (status) {
      case 'approved':
        return <span className="admin-badge admin-badge-success">Approved</span>;
      case 'rejected':
        return <span className="admin-badge admin-badge-danger">Rejected</span>;
      case 'pending':
      default:
        return <span className="admin-badge admin-badge-warning">Pending Review</span>;
    }
  };

  const formatDate = (iso: string | null) => {
    if (!iso) return '--';
    return new Date(iso).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const docTypeIcon = (type: string) => {
    switch (type) {
      case 'driver_license':
        return '🪪';
      case 'insurance':
        return '🛡️';
      case 'registration':
        return '📋';
      case 'background_check':
        return '🔍';
      default:
        return '📄';
    }
  };

  const exportCSV = () => {
    const headers = ['Chauffeur', 'Document Type', 'Submitted', 'Expiry', 'Status'];
    const rows = filtered.flatMap((g) =>
      g.docs.map((d) => [
        g.driver_name,
        typeLabel(d.type),
        formatDate(d.created_at),
        formatDate(d.expires_at),
        d.status,
      ])
    );
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `document_verifications_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="doc-page">
      {/* ── Page Header ── */}
      <div className="admin-page-header">
        <div>
          <h1>Document Verification</h1>
          <p>Review and verify chauffeur credentials, licenses, insurance policies, and background checks.</p>
        </div>
        <div className="admin-page-header-actions">
          <button className="admin-btn admin-btn-outline" onClick={expandAll} style={{ fontSize: '0.8rem' }}>
            Expand All
          </button>
          <button className="admin-btn admin-btn-outline" onClick={collapseAll} style={{ fontSize: '0.8rem' }}>
            Collapse All
          </button>
          <button className="admin-btn" onClick={exportCSV}>
            <Download size={16} />
            Export CSV
          </button>
        </div>
      </div>

      {/* ── Stats Bar ── */}
      <div className="pricing-stats-bar">
        <div className="pricing-stat-card">
          <div className="pricing-stat-icon" style={{ background: 'rgba(244, 197, 34, 0.12)', color: '#F4C522' }}>
            <Users size={18} />
          </div>
          <div>
            <div className="pricing-stat-value">{stats.chauffeurs}</div>
            <div className="pricing-stat-label">Total Chauffeurs</div>
          </div>
        </div>
        <div className="pricing-stat-card">
          <div className="pricing-stat-icon" style={{ background: 'rgba(234, 179, 8, 0.12)', color: '#eab308' }}>
            <Clock size={18} />
          </div>
          <div>
            <div className="pricing-stat-value">{stats.pending}</div>
            <div className="pricing-stat-label">Pending Review</div>
          </div>
        </div>
        <div className="pricing-stat-card">
          <div className="pricing-stat-icon" style={{ background: 'rgba(16, 185, 129, 0.12)', color: '#10b981' }}>
            <ShieldCheck size={18} />
          </div>
          <div>
            <div className="pricing-stat-value">{stats.approved}</div>
            <div className="pricing-stat-label">Approved Docs</div>
          </div>
        </div>
        <div className="pricing-stat-card">
          <div className="pricing-stat-icon" style={{ background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444' }}>
            <ShieldAlert size={18} />
          </div>
          <div>
            <div className="pricing-stat-value">{stats.rejected}</div>
            <div className="pricing-stat-label">Rejected Docs</div>
          </div>
        </div>
      </div>

      {/* ── Main Content Container ── */}
      <div className="doc-content-card">
        {/* Filter Bar & Tabs */}
        <div className="doc-filter-header">
          <div className="doc-tabs">
            {(['all', 'pending', 'approved', 'rejected'] as const).map((t) => {
              const count =
                t === 'all'
                  ? stats.totalDocs
                  : t === 'pending'
                  ? stats.pending
                  : t === 'approved'
                  ? stats.approved
                  : stats.rejected;

              return (
                <button
                  key={t}
                  className={`doc-tab ${statusFilter === t ? 'active' : ''}`}
                  onClick={() => setStatusFilter(t)}
                >
                  <span className="doc-tab-label">
                    {t === 'all' ? 'All Documents' : t.charAt(0).toUpperCase() + t.slice(1)}
                  </span>
                  <span className="doc-tab-count">{count}</span>
                </button>
              );
            })}
          </div>

          <div className="admin-search-wrapper" style={{ maxWidth: 300 }}>
            <Search
              size={16}
              style={{
                position: 'absolute',
                left: '1rem',
                top: '50%',
                transform: 'translateY(-50%)',
                color: 'var(--admin-text-muted)',
              }}
            />
            <input
              type="text"
              placeholder="Search by chauffeur..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="admin-search-input"
            />
          </div>
        </div>

        {/* Content Body */}
        {loading ? (
          <div className="pricing-loading" style={{ padding: '4rem 2rem' }}>
            <div className="pricing-loading-spinner" />
            <p style={{ color: 'var(--admin-text-muted)', fontSize: '0.9rem' }}>Loading documents…</p>
          </div>
        ) : error ? (
          <div style={{ padding: '4rem 2rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error}</p>
            <button className="admin-btn" onClick={() => { setError(null); setLoading(true); fetchDocuments(); }}>
              Try Again
            </button>
          </div>
        ) : filtered.length === 0 ? (
          <div className="doc-empty-state">
            <div className="doc-empty-icon">📂</div>
            <h3>No documents found</h3>
            <p>
              {search
                ? `No chauffeurs matching "${search}" found.`
                : statusFilter !== 'all'
                ? `No ${statusFilter} documents to display.`
                : 'No document submissions found.'}
            </p>
          </div>
        ) : (
          <div className="doc-groups-list">
            {filtered.map((group) => {
              const groupPendingCount = group.docs.filter((d) => d.status === 'pending').length;

              return (
                <div
                  key={group.driver_id}
                  className={`doc-group-card ${group.expanded ? 'expanded' : ''}`}
                >
                  <div className="doc-group-header" onClick={() => toggleExpand(group.driver_id)}>
                    <div className="doc-group-info">
                      <div className="doc-avatar-badge">
                        {group.driver_name.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <span className="doc-driver-name">{group.driver_name}</span>
                        <span className="doc-driver-sub">
                          {group.docs.length} document{group.docs.length !== 1 ? 's' : ''} submitted
                        </span>
                      </div>
                    </div>

                    <div className="doc-group-header-right">
                      {groupPendingCount > 0 && (
                        <span className="doc-pending-pill">
                          {groupPendingCount} PENDING
                        </span>
                      )}
                      <div className={`vip-chevron ${group.expanded ? 'open' : ''}`}>
                        <ChevronDown size={18} />
                      </div>
                    </div>
                  </div>

                  {group.expanded && (
                    <div className="doc-group-body">
                      {group.docs.map((doc) => (
                        <div key={doc.id} className="doc-item-row">
                          <div className="doc-item-left">
                            <span className="doc-item-icon">{docTypeIcon(doc.type)}</span>
                            <div>
                              <div className="doc-item-title">{typeLabel(doc.type)}</div>
                              <div className="doc-item-meta">
                                <span>Submitted: {formatDate(doc.created_at)}</span>
                                <span>·</span>
                                <span>Expires: {formatDate(doc.expires_at)}</span>
                              </div>
                              {doc.rejection_reason && (
                                <div className="doc-rejection-reason">
                                  Reason for rejection: {doc.rejection_reason}
                                </div>
                              )}
                            </div>
                          </div>

                          <div className="doc-item-right">
                            {statusBadge(doc.status)}

                            {doc.file_url && (
                              <button
                                onClick={async (e) => {
                                  e.stopPropagation();
                                  setPreviewDoc(doc);
                                  setDiditData(null);
                                  setDiditError('');
                                  if (doc.file_url.startsWith('didit://')) {
                                    const sid = doc.file_url.replace('didit://', '');
                                    setDiditLoading(true);
                                    try {
                                      const { data: fnData, error: fnError } = await supabase.functions.invoke(
                                        'didit-lookup',
                                        { body: { session_id: sid } }
                                      );
                                      if (fnError) throw fnError;
                                      if (fnData?.error)
                                        throw new Error(fnData.error + (fnData.details ? ': ' + fnData.details : ''));
                                      setDiditData(fnData);
                                    } catch (err: any) {
                                      setDiditError(JSON.stringify(err));
                                    } finally {
                                      setDiditLoading(false);
                                    }
                                  }
                                }}
                                className="admin-btn admin-btn-outline"
                                style={{ padding: '0.4rem 0.75rem', fontSize: '0.8rem', gap: '0.35rem' }}
                                title="Inspect document"
                              >
                                <Eye size={14} /> View
                              </button>
                            )}

                            {doc.status === 'pending' && (
                              <div className="doc-action-btns">
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleApprove(doc.id);
                                  }}
                                  disabled={actionLoading}
                                  className="doc-approve-btn"
                                  title="Approve Document"
                                >
                                  <CheckCircle size={14} /> Approve
                                </button>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleReject(doc.id);
                                  }}
                                  disabled={actionLoading}
                                  className="doc-reject-btn"
                                  title="Reject Document"
                                >
                                  <XCircle size={14} /> Reject
                                </button>
                              </div>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* ── Document Inspection Modal ── */}
      {previewDoc && (
        <div
          className="admin-modal-overlay"
          onClick={() => {
            setPreviewDoc(null);
            setDiditData(null);
            setDiditError('');
          }}
          style={{ zIndex: 200 }}
        >
          <div
            className="admin-modal doc-preview-modal"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="doc-preview-header">
              <div>
                <h2>{typeLabel(previewDoc.type)}</h2>
                <p className="doc-preview-subtitle">
                  Submitted {formatDate(previewDoc.created_at)}
                  {previewDoc.expires_at && ` · Expires ${formatDate(previewDoc.expires_at)}`}
                </p>
              </div>
              <button
                className="vip-modal-close"
                onClick={() => {
                  setPreviewDoc(null);
                  setDiditData(null);
                  setDiditError('');
                }}
              >
                ✕
              </button>
            </div>

            <div className="doc-preview-viewer">
              {previewDoc.file_url.startsWith('didit://') ? (
                diditLoading ? (
                  <div className="pricing-loading">
                    <Loader2 size={32} style={{ color: '#F4C522', animation: 'spin 1s linear infinite' }} />
                    <p style={{ fontSize: '0.85rem', color: 'var(--admin-text-muted)' }}>Fetching Didit verification details…</p>
                  </div>
                ) : diditError ? (
                  <div style={{ color: '#fca5a5', fontSize: '0.85rem', textAlign: 'center' }}>
                    <p style={{ margin: '0 0 0.5rem', fontWeight: 600 }}>Failed to load verification session</p>
                    <code style={{ fontSize: '0.75rem', color: '#71717a', wordBreak: 'break-all' }}>
                      {previewDoc.file_url}
                    </code>
                  </div>
                ) : diditData ? (
                  <div className="didit-data-container">
                    {diditData.session?.documents?.map((doc: any, i: number) => (
                      <div key={i} className="didit-doc-block">
                        <p className="didit-block-title">{doc.type}</p>
                        <div className="didit-images-grid">
                          {doc.front_image && (
                            <img src={`data:image/png;base64,${doc.front_image}`} alt={`${doc.type} front`} />
                          )}
                          {doc.back_image && (
                            <img src={`data:image/png;base64,${doc.back_image}`} alt={`${doc.type} back`} />
                          )}
                          {doc.face_image && (
                            <img src={`data:image/png;base64,${doc.face_image}`} alt="face" />
                          )}
                          {doc.images?.map(
                            (img: any, j: number) =>
                              img.image && (
                                <img
                                  key={j}
                                  src={img.image.startsWith('data:') ? img.image : `data:image/png;base64,${img.image}`}
                                  alt={`${doc.type} ${img.type}`}
                                />
                              )
                          )}
                        </div>
                      </div>
                    ))}
                    {diditData.session?.selfie?.image && (
                      <div className="didit-doc-block">
                        <p className="didit-block-title">Verification Selfie</p>
                        <img
                          src={`data:image/png;base64,${diditData.session.selfie.image}`}
                          alt="selfie"
                          style={{ maxWidth: 280, borderRadius: 12 }}
                        />
                      </div>
                    )}
                    {!diditData.session?.documents?.length && !diditData.session?.selfie && (
                      <div style={{ color: 'var(--admin-text-muted)', fontSize: '0.85rem', textAlign: 'center' }}>
                        <p style={{ margin: '0 0 0.25rem' }}>No verification images stored for this session</p>
                        <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--admin-text-faint)' }}>
                          Status: {diditData.session?.status || 'unknown'}
                        </p>
                      </div>
                    )}
                  </div>
                ) : (
                  <div style={{ color: 'var(--admin-text-muted)', fontSize: '0.9rem', textAlign: 'center' }}>
                    <div style={{ fontSize: '2.5rem', marginBottom: '0.5rem' }}>🪪</div>
                    <p style={{ margin: '0 0 0.25rem', fontWeight: 600 }}>Didit Identity Reference</p>
                    <code style={{ fontSize: '0.75rem', color: 'var(--admin-text-faint)', wordBreak: 'break-all' }}>
                      {previewDoc.file_url}
                    </code>
                  </div>
                )
              ) : (
                <img
                  src={previewDoc.file_url}
                  alt={typeLabel(previewDoc.type)}
                  className="doc-preview-img"
                  onError={(e) => {
                    (e.target as HTMLImageElement).style.display = 'none';
                    const parent = (e.target as HTMLImageElement).parentElement;
                    if (parent) {
                      const fallback = document.createElement('div');
                      fallback.style.cssText = 'color: var(--admin-text-muted); font-size: 0.9rem; text-align: center; padding: 2rem;';
                      fallback.innerHTML = '<p>Unable to render preview for this file URL.</p>';
                      parent.appendChild(fallback);
                    }
                  }}
                />
              )}
            </div>

            <div className="doc-preview-footer">
              {previewDoc.status === 'pending' ? (
                <>
                  <button
                    onClick={() => {
                      handleApprove(previewDoc.id);
                      setPreviewDoc(null);
                    }}
                    disabled={actionLoading}
                    className="doc-approve-btn"
                  >
                    <CheckCircle size={15} /> Approve Document
                  </button>
                  <button
                    onClick={() => {
                      handleReject(previewDoc.id);
                      setPreviewDoc(null);
                    }}
                    disabled={actionLoading}
                    className="doc-reject-btn"
                  >
                    <XCircle size={15} /> Reject Document
                  </button>
                </>
              ) : (
                <div style={{ marginLeft: 'auto' }}>
                  {statusBadge(previewDoc.status)}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ── Reject Reason Modal ── */}
      {rejectModal.open && (
        <div
          className="admin-modal-overlay"
          style={{ zIndex: 1000 }}
          onClick={() => setRejectModal({ open: false, docId: null })}
        >
          <div className="admin-modal vip-modal" onClick={(e) => e.stopPropagation()} style={{ width: 440 }}>
            <div className="vip-modal-header">
              <h2>Reject Document</h2>
              <button
                className="vip-modal-close"
                onClick={() => setRejectModal({ open: false, docId: null })}
              >
                ✕
              </button>
            </div>

            <p style={{ fontSize: '0.85rem', color: 'var(--admin-text-muted)', marginBottom: '1rem' }}>
              Please provide a clear reason for rejecting this document so the chauffeur knows what to resubmit.
            </p>

            <textarea
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder="e.g. Image blurry, license expired, name mismatch…"
              rows={4}
              className="admin-search-input"
              style={{
                width: '100%',
                padding: '0.85rem',
                borderRadius: '12px',
                resize: 'vertical',
                fontFamily: 'inherit',
                marginBottom: '1.25rem',
              }}
            />

            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
              <button
                onClick={() => setRejectModal({ open: false, docId: null })}
                className="admin-btn admin-btn-outline"
              >
                Cancel
              </button>
              <button
                onClick={confirmReject}
                disabled={actionLoading}
                className="admin-btn"
                style={{ background: '#ef4444', borderColor: '#ef4444' }}
              >
                Confirm Rejection
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
