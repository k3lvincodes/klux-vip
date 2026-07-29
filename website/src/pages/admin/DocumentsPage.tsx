import { useEffect, useState, useMemo } from 'react';
import { Search, Download, Eye, CheckCircle, XCircle, ChevronDown, Loader2 } from 'lucide-react';
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
          driver_name: nameMap.get(driver_id) || 'Unknown',
          docs,
          expanded: false,
        }))
      );
    } catch (err) {
      setError('Failed to load documents');
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    if (!search.trim()) return groups;
    const q = search.toLowerCase();
    return groups.filter((g) => g.driver_name.toLowerCase().includes(q));
  }, [groups, search]);

  const toggleExpand = (driver_id: string) => {
    setGroups((prev) =>
      prev.map((g) => (g.driver_id === driver_id ? { ...g, expanded: !g.expanded } : g))
    );
  };

  const handleApprove = async (docId: string) => {
    setActionLoading(true);
    try {
      const { error } = await supabase
        .from('driver_documents')
        .update({ status: 'approved', updated_at: new Date().toISOString() })
        .eq('id', docId);

      if (error) {
        return;
      }

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
        return 'Background Check';
      default:
        return type;
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
        return <span className="admin-badge admin-badge-warning">Pending</span>;
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
    a.download = `documents_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
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
        <div
          style={{
            padding: '1rem 1.5rem',
            borderBottom: '1px solid rgba(255,255,255,0.05)',
            display: 'flex',
            gap: '1rem',
          }}
        >
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <Search
              size={16}
              style={{
                position: 'absolute',
                left: '1rem',
                top: '50%',
                transform: 'translateY(-50%)',
                color: '#a1a1aa',
              }}
            />
            <input
              type="text"
              placeholder="Search by chauffeur name..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                width: '100%',
                padding: '0.6rem 1rem 0.6rem 2.5rem',
                background: 'rgba(0,0,0,0.2)',
                border: '1px solid rgba(255,255,255,0.1)',
                borderRadius: '8px',
                color: '#fff',
                outline: 'none',
              }}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>
            Loading documents...
          </div>
        ) : error ? (
          <div style={{ padding: '3rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error}</p>
            <button className="admin-btn" onClick={() => { setError(null); setLoading(true); fetchDocuments(); }}>Try Again</button>
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>
            {search ? 'No chauffeurs match your search.' : 'No documents found.'}
          </div>
        ) : (
          <div>
            {filtered.map((group) => (
              <div key={group.driver_id} className="admin-card" style={{ margin: '0.75rem 1.25rem' }}>
                <div
                  onClick={() => toggleExpand(group.driver_id)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '1rem 1.25rem',
                    cursor: 'pointer',
                    userSelect: 'none',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
                    <div
                      style={{
                        width: 36,
                        height: 36,
                        borderRadius: '50%',
                        background: 'rgba(244, 197, 34, 0.1)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: 600,
                        fontSize: '0.85rem',
                        color: '#F4C522',
                      }}
                    >
                      {group.driver_name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <div style={{ fontWeight: 600, fontSize: '0.95rem' }}>{group.driver_name}</div>
                      <div style={{ fontSize: '0.75rem', color: '#a1a1aa' }}>
                        {group.docs.length} document{group.docs.length !== 1 ? 's' : ''}
                        {' · '}
                        {group.docs.filter((d) => d.status === 'pending').length} pending
                      </div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    {group.docs.some((d) => d.status === 'pending') && (
                      <span
                        style={{
                          background: 'rgba(244, 197, 34, 0.15)',
                          color: '#F4C522',
                          fontSize: '0.65rem',
                          fontWeight: 600,
                          padding: '0.15rem 0.5rem',
                          borderRadius: '999px',
                        }}
                      >
                        PENDING
                      </span>
                    )}
                    <ChevronDown
                      size={18}
                      style={{
                        color: '#a1a1aa',
                        transition: 'transform 0.3s ease',
                        transform: group.expanded ? 'rotate(180deg)' : 'rotate(0deg)',
                      }}
                    />
                  </div>
                </div>

                {group.expanded && (
                  <div style={{ borderTop: '1px solid rgba(255,255,255,0.05)' }}>
                    {group.docs.map((doc) => (
                      <div
                        key={doc.id}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '1rem',
                          padding: '0.85rem 1.25rem',
                          borderBottom: '1px solid rgba(255,255,255,0.03)',
                        }}
                      >
                        <span style={{ fontSize: '1.2rem' }}>{docTypeIcon(doc.type)}</span>
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div style={{ fontWeight: 500, fontSize: '0.9rem' }}>{typeLabel(doc.type)}</div>
                          <div style={{ fontSize: '0.75rem', color: '#71717a', display: 'flex', gap: '1rem' }}>
                            <span>Submitted: {formatDate(doc.created_at)}</span>
                            <span>Expires: {formatDate(doc.expires_at)}</span>
                          </div>
                          {doc.rejection_reason && (
                            <div style={{ fontSize: '0.75rem', color: '#fca5a5', marginTop: '0.2rem' }}>
                              Reason: {doc.rejection_reason}
                            </div>
                          )}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexShrink: 0 }}>
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
                                    const { data: fnData, error: fnError } = await supabase.functions.invoke('didit-lookup', {
                                      body: { session_id: sid },
                                    });
                                    if (fnError) throw fnError;
                                    if (fnData?.error) throw new Error(fnData.error + (fnData.details ? ': ' + fnData.details : ''));
                                    setDiditData(fnData);
                                  } catch (err: any) {
                                    setDiditError(JSON.stringify(err));
                                  } finally {
                                    setDiditLoading(false);
                                  }
                                }
                              }}
                              className="admin-btn admin-btn-outline"
                              style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem', cursor: 'pointer' }}
                              title="Preview document"
                            >
                              <Eye size={14} />
                            </button>
                          )}
                          {doc.status === 'pending' && (
                            <>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleApprove(doc.id);
                                }}
                                disabled={actionLoading}
                                style={{
                                  padding: '0.4rem 0.6rem',
                                  fontSize: '0.8rem',
                                  background: 'rgba(16,185,129,0.1)',
                                  color: '#10b981',
                                  border: '1px solid rgba(16,185,129,0.2)',
                                  borderRadius: '8px',
                                  cursor: 'pointer',
                                  display: 'flex',
                                  alignItems: 'center',
                                }}
                                title="Approve"
                              >
                                <CheckCircle size={14} />
                              </button>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleReject(doc.id);
                                }}
                                disabled={actionLoading}
                                style={{
                                  padding: '0.4rem 0.6rem',
                                  fontSize: '0.8rem',
                                  background: 'rgba(239,68,68,0.1)',
                                  color: '#ef4444',
                                  border: '1px solid rgba(239,68,68,0.2)',
                                  borderRadius: '8px',
                                  cursor: 'pointer',
                                  display: 'flex',
                                  alignItems: 'center',
                                }}
                                title="Reject"
                              >
                                <XCircle size={14} />
                              </button>
                            </>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {previewDoc && (
        <div
          className="admin-modal-overlay"
          onClick={() => { setPreviewDoc(null); setDiditData(null); setDiditError(''); }}
          style={{ zIndex: 200 }}
        >
          <div
            className="admin-modal"
            onClick={(e) => e.stopPropagation()}
            style={{
              width: '90vw',
              maxWidth: '800px',
              padding: '1.5rem',
              display: 'flex',
              flexDirection: 'column',
              gap: '1rem',
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <div>
                <h2 style={{ margin: 0, fontSize: '1.1rem' }}>{typeLabel(previewDoc.type)}</h2>
                <p style={{ margin: '0.2rem 0 0', fontSize: '0.8rem', color: '#a1a1aa' }}>
                  {formatDate(previewDoc.created_at)}
                  {previewDoc.expires_at && ` · Expires ${formatDate(previewDoc.expires_at)}`}
                </p>
              </div>
              <button
                onClick={() => setPreviewDoc(null)}
                style={{
                  background: 'rgba(255,255,255,0.06)',
                  border: '1px solid rgba(255,255,255,0.08)',
                  color: '#a1a1aa',
                  width: 32,
                  height: 32,
                  borderRadius: 8,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '1.1rem',
                }}
              >
                ✕
              </button>
            </div>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: '#000',
                borderRadius: 12,
                overflow: 'hidden',
                minHeight: 120,
                maxHeight: '65vh',
                padding: '2rem',
              }}
            >
              {previewDoc.file_url.startsWith('didit://') ? (
                diditLoading ? (
                  <Loader2 size={32} style={{ color: '#a1a1aa', animation: 'spin 1s linear infinite' }} />
                ) : diditError ? (
                  <div style={{ color: '#fca5a5', fontSize: '0.85rem', textAlign: 'center' }}>
                    <p style={{ margin: '0 0 0.5rem' }}>Failed to load verification data</p>
                    <code style={{ fontSize: '0.7rem', color: '#71717a', wordBreak: 'break-all' }}>
                      {previewDoc.file_url}
                    </code>
                  </div>
                ) : diditData ? (
                  <div style={{ width: '100%', maxHeight: '60vh', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {diditData.session?.documents?.map((doc: any, i: number) => (
                      <div key={i}>
                        <p style={{ margin: '0 0 0.5rem', fontSize: '0.8rem', fontWeight: 600, color: '#a1a1aa', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{doc.type}</p>
                        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
                          {doc.front_image && (
                            <img src={`data:image/png;base64,${doc.front_image}`} alt={`${doc.type} front`} style={{ maxWidth: '100%', maxHeight: '40vh', borderRadius: 8, objectFit: 'contain' }} />
                          )}
                          {doc.back_image && (
                            <img src={`data:image/png;base64,${doc.back_image}`} alt={`${doc.type} back`} style={{ maxWidth: '100%', maxHeight: '40vh', borderRadius: 8, objectFit: 'contain' }} />
                          )}
                          {doc.face_image && (
                            <img src={`data:image/png;base64,${doc.face_image}`} alt="face" style={{ maxWidth: '100%', maxHeight: '40vh', borderRadius: 8, objectFit: 'contain' }} />
                          )}
                          {doc.images?.map((img: any, j: number) => (
                            img.image && (
                              <img key={j} src={img.image.startsWith('data:') ? img.image : `data:image/png;base64,${img.image}`} alt={`${doc.type} ${img.type}`} style={{ maxWidth: '100%', maxHeight: '40vh', borderRadius: 8, objectFit: 'contain' }} />
                            )
                          ))}
                        </div>
                      </div>
                    ))}
                    {diditData.session?.selfie?.image && (
                      <div>
                        <p style={{ margin: '0 0 0.5rem', fontSize: '0.8rem', fontWeight: 600, color: '#a1a1aa', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Selfie</p>
                        <img src={`data:image/png;base64,${diditData.session.selfie.image}`} alt="selfie" style={{ maxWidth: '100%', maxHeight: '40vh', borderRadius: 8, objectFit: 'contain' }} />
                      </div>
                    )}
                    {(!diditData.session?.documents?.length && !diditData.session?.selfie) && (
                      <div style={{ color: '#a1a1aa', fontSize: '0.85rem', textAlign: 'center' }}>
                        <p style={{ margin: '0 0 0.25rem' }}>No images available for this session</p>
                        <p style={{ margin: 0, fontSize: '0.75rem', color: '#71717a' }}>Status: {diditData.session?.status || 'unknown'}</p>
                      </div>
                    )}
                  </div>
                ) : (
                  <div style={{ color: '#a1a1aa', fontSize: '0.9rem', textAlign: 'center' }}>
                    <div style={{ fontSize: '2rem', marginBottom: '0.75rem' }}>🪪</div>
                    <p style={{ margin: '0 0 0.25rem' }}>Identity verification reference</p>
                    <code style={{ fontSize: '0.75rem', color: '#71717a', wordBreak: 'break-all' }}>
                      {previewDoc.file_url}
                    </code>
                  </div>
                )
              ) : (
                <img
                  src={previewDoc.file_url}
                  alt={typeLabel(previewDoc.type)}
                  style={{
                    maxWidth: '100%',
                    maxHeight: '65vh',
                    objectFit: 'contain',
                    borderRadius: 8,
                  }}
                  onError={(e) => {
                    (e.target as HTMLImageElement).style.display = 'none';
                    const parent = (e.target as HTMLImageElement).parentElement;
                    if (parent) {
                      const fallback = document.createElement('div');
                      fallback.style.cssText = 'color: #a1a1aa; font-size: 0.9rem; text-align: center;';
                      fallback.innerHTML = '<p>Failed to load document.</p>';
                      parent.appendChild(fallback);
                    }
                  }}
                />
              )}
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem' }}>
              {previewDoc.status === 'pending' && (
                <>
                  <button
                    onClick={() => {
                      handleApprove(previewDoc.id);
                      setPreviewDoc(null);
                    }}
                    disabled={actionLoading}
                    style={{
                      padding: '0.5rem 1rem',
                      fontSize: '0.85rem',
                      fontWeight: 600,
                      background: 'rgba(16,185,129,0.1)',
                      color: '#10b981',
                      border: '1px solid rgba(16,185,129,0.2)',
                      borderRadius: '8px',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.4rem',
                    }}
                  >
                    <CheckCircle size={14} />
                    Approve
                  </button>
                  <button
                    onClick={() => {
                      handleReject(previewDoc.id);
                      setPreviewDoc(null);
                    }}
                    disabled={actionLoading}
                    style={{
                      padding: '0.5rem 1rem',
                      fontSize: '0.85rem',
                      fontWeight: 600,
                      background: 'rgba(239,68,68,0.1)',
                      color: '#ef4444',
                      border: '1px solid rgba(239,68,68,0.2)',
                      borderRadius: '8px',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.4rem',
                    }}
                  >
                    <XCircle size={14} />
                    Reject
                  </button>
                </>
              )}
              {previewDoc.status !== 'pending' && (
                <span className="admin-badge" style={{ fontSize: '0.85rem' }}>
                  {statusBadge(previewDoc.status)}
                </span>
              )}
            </div>
          </div>
        </div>
      )}

      {rejectModal.open && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000,
        }} onClick={() => setRejectModal({ open: false, docId: null })}>
          <div style={{
            background: '#1a1a1a', border: '1px solid #333', borderRadius: '12px',
            padding: '24px', width: '400px', maxWidth: '90vw',
          }} onClick={(e) => e.stopPropagation()}>
            <h3 style={{ margin: '0 0 16px', color: '#fff', fontSize: '1.1rem' }}>Rejection Reason</h3>
            <textarea
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder="Enter reason for rejection (optional)"
              rows={3}
              style={{
                width: '100%', padding: '12px', borderRadius: '8px', border: '1px solid #333',
                background: '#0a0a0a', color: '#e0e0e0', fontSize: '0.9rem', resize: 'vertical',
                fontFamily: 'inherit', boxSizing: 'border-box',
              }}
            />
            <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end', marginTop: '16px' }}>
              <button
                onClick={() => setRejectModal({ open: false, docId: null })}
                style={{
                  padding: '8px 16px', borderRadius: '8px', border: '1px solid #333',
                  background: 'transparent', color: '#999', cursor: 'pointer', fontSize: '0.9rem',
                }}
              >
                Cancel
              </button>
              <button
                onClick={confirmReject}
                disabled={actionLoading}
                style={{
                  padding: '8px 16px', borderRadius: '8px', border: 'none',
                  background: '#ef4444', color: '#fff', cursor: 'pointer', fontSize: '0.9rem',
                }}
              >
                Reject Document
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
