import { useEffect, useState, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  Search,
  Download,
  Eye,
  CheckCircle,
  XCircle,
  ChevronDown,
  Clock,
  ShieldCheck,
  ShieldAlert,
  Users,
  ChevronsUpDown,
  RotateCw,
  X,
  FileCheck,
  ExternalLink,
  UserCheck
} from 'lucide-react';

import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
import { AdminDrawer } from '../../components/ui/AdminDrawer';

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
  const toast = useToast();
  const [searchParams, setSearchParams] = useSearchParams();
  const driverParam = searchParams.get('driver');

  const [groups, setGroups] = useState<DriverGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [previewDoc, setPreviewDoc] = useState<Doc | null>(null);
  const [diditData, setDiditData] = useState<any>(null);
  const [diditLoading, setDiditLoading] = useState(false);
  const [diditError, setDiditError] = useState('');
  const [rejectDocId, setRejectDocId] = useState<string | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    fetchDocuments();
  }, [driverParam]);

  const fetchDocuments = async () => {
    try {
      setLoading(true);
      setError(null);
      const { data: docs, error } = await supabase
        .from('driver_documents')
        .select('id, driver_id, type, status, file_url, rejection_reason, expires_at, created_at')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Filter out redundant "driver_license" entries as all chauffeur license details and
      // ID document images are already displayed within the "Background Security Verification" Didit modal.
      const displayDocs = (docs || []).filter((d) => d.type !== 'driver_license');

      const ids = [...new Set(displayDocs.map((d) => d.driver_id))];
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .in('id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']);

      const nameMap = new Map<string, string>();
      profiles?.forEach((p) => {
        nameMap.set(p.id, [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email);
      });

      const grouped = new Map<string, Doc[]>();
      displayDocs.forEach((d) => {
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

      const loadedGroups = [...grouped.entries()].map(([driver_id, docs]) => ({
        driver_id,
        driver_name: nameMap.get(driver_id) || 'Unknown Chauffeur',
        docs,
        expanded: driverParam ? driver_id === driverParam : false,
      }));

      setGroups(loadedGroups);

      if (driverParam) {
        const targetGroup = loadedGroups.find((g) => g.driver_id === driverParam);
        if (targetGroup && targetGroup.docs.length > 0) {
          openDocPreview(targetGroup.docs[0]);
        }
      }
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
        if (driverParam && g.driver_id !== driverParam) return null;
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
  }, [groups, search, statusFilter, driverParam]);

  const toggleExpand = (driver_id: string) => {
    setGroups((prev) =>
      prev.map((g) => (g.driver_id === driver_id ? { ...g, expanded: !g.expanded } : g))
    );
  };

  const allExpanded = filtered.length > 0 && filtered.every((g) => g.expanded);

  const toggleAll = () => {
    const newState = !allExpanded;
    setGroups((prev) => prev.map((g) => ({ ...g, expanded: newState })));
  };

  const openDocPreview = async (doc: Doc) => {
    setPreviewDoc(doc);
    setDiditData(null);
    setDiditError('');

    if (doc.file_url.startsWith('didit://')) {
      const sid = doc.file_url.replace('didit://', '');
      setDiditLoading(true);
      try {
        let payload: any = null;

        // 1. Try Vite local dev proxy /api/didit/${sid}/decision/
        try {
          const proxyRes = await fetch(`/api/didit/${sid}/decision/`);
          if (proxyRes.ok) {
            const pJson = await proxyRes.json();
            if (pJson && (pJson.session_id || pJson.id_verifications || pJson.status)) {
              payload = pJson;
            }
          }
        } catch {
          // Fall through to Edge Function
        }

        // 2. Try Supabase Edge Function 'didit-lookup'
        if (!payload) {
          try {
            const { data: fnData, error: fnError } = await supabase.functions.invoke(
              'didit-lookup',
              { body: { session_id: sid } }
            );
            if (!fnError && fnData) {
              payload = fnData.session || fnData;
            }
          } catch {
            // Fall through to direct call
          }
        }

        // 3. Fallback direct Didit API call with x-api-key
        if (!payload) {
          try {
            const directRes = await fetch(`https://verification.didit.me/v3/session/${sid}/decision/`, {
              headers: {
                'x-api-key': 'Ljgu4XQ0a_Ux3yMkPi6nLSGijRHOuUmTeBXyzPVVsjA',
              },
            });
            if (directRes.ok) {
              payload = await directRes.json();
            }
          } catch {
            // Direct call failed
          }
        }

        if (payload && (payload.id_verifications || payload.session_id || payload.session || payload.status)) {
          const session = payload.session || payload;
          setDiditData(session);
        } else {
          throw new Error('Verification session telemetry could not be retrieved from the Didit verification gateway.');
        }
      } catch (err: any) {
        setDiditError(err.message || 'Unable to connect to Didit identity verification protocol.');
      } finally {
        setDiditLoading(false);
      }
    }
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

      // Find the driver_id for this doc and check if all required docs are now approved
      const group = groups.find((g) => g.docs.some((d) => d.id === docId));
      const targetDoc = group?.docs.find((d) => d.id === docId);

      if (group && targetDoc?.type === 'background_check') {
        // Automatically approve any associated driver_license row in DB as well
        await supabase
          .from('driver_documents')
          .update({ status: 'approved', updated_at: new Date().toISOString() })
          .eq('driver_id', group.driver_id)
          .eq('type', 'driver_license');
      }

      if (group) {
        const updatedDocs = group.docs.map((d) => (d.id === docId ? { ...d, status: 'approved' } : d));
        const requiredTypes = ['insurance', 'registration', 'background_check'];
        const allApproved = requiredTypes.every((t) =>
          !updatedDocs.some((d) => d.type === t) || updatedDocs.some((d) => d.type === t && d.status === 'approved')
        );
        if (allApproved) {
          try {
            const { error: rpcErr } = await supabase.rpc('admin_set_driver_status', {
              p_driver_id: group.driver_id,
              p_status: 'approved',
            });
            if (rpcErr) throw rpcErr;
          } catch {
            await supabase
              .from('driver_details')
              .update({ verification_status: 'approved', status: 'approved', updated_at: new Date().toISOString() })
              .eq('profile_id', group.driver_id);
            await supabase
              .from('profiles')
              .update({ verification_status: 'approved', updated_at: new Date().toISOString() })
              .eq('id', group.driver_id);
          }
        }
      }
      toast.success('Credential approved successfully');
    } catch (err: any) {
      console.error('Failed to approve credential:', err);
      toast.error('Failed to approve credential');
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = (docId: string) => {
    setRejectDocId(docId);
    setRejectReason('');
  };

  const confirmReject = async () => {
    if (!rejectDocId) return;
    setActionLoading(true);
    try {
      const reason = rejectReason.trim();

      const { error } = await supabase
        .from('driver_documents')
        .update({ status: 'rejected', rejection_reason: reason || null, updated_at: new Date().toISOString() })
        .eq('id', rejectDocId);

      if (error) {
        toast.error('Failed to reject document');
        setRejectDocId(null);
        return;
      }

      setGroups((prev) =>
        prev.map((g) => ({
          ...g,
          docs: g.docs.map((d) =>
            d.id === rejectDocId ? { ...d, status: 'rejected', rejection_reason: reason || null } : d
          ),
        }))
      );
      toast.success('Document credential rejected with feedback');
      setRejectDocId(null);
      setPreviewDoc(null);
    } finally {
      setActionLoading(false);
    }
  };

  const typeLabel = (type: string) => {
    switch (type) {
      case 'driver_license':
        return "Chauffeur's License";
      case 'insurance':
        return 'Vehicle Insurance Policy';
      case 'registration':
        return 'Vehicle Registration Certification';
      case 'background_check':
        return 'Background Security Verification';
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
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* ── Page Header ── */}
      <div className="admin-page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1>Document Verification</h1>
          <p>Compliance verification for chauffeurs, licenses, insurance policies, and security checks</p>
        </div>
        <div className="admin-page-header-actions">
          <button
            className="admin-btn admin-btn-outline"
            onClick={toggleAll}
            title={allExpanded ? 'Collapse all' : 'Expand all'}
          >
            <ChevronsUpDown size={14} /> {allExpanded ? 'Collapse All' : 'Expand All'}
          </button>
          <button className="admin-btn admin-btn-outline" onClick={fetchDocuments} title="Refresh records">
            <RotateCw size={14} /> Refresh
          </button>
          <button className="admin-btn" onClick={exportCSV}>
            <Download size={14} /> Export CSV
          </button>
        </div>
      </div>

      {/* ── Summary KPI Cards ── */}
      <div className="admin-kpi-summary-grid">
        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Registered Chauffeurs</span>
            <div className="admin-kpi-value">{stats.chauffeurs}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(255, 255, 255, 0.03)', color: '#fff' }}>
            <Users size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Pending Verification</span>
            <div className="admin-kpi-value">{stats.pending}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(245, 158, 11, 0.08)', color: 'var(--admin-warning)', borderColor: 'rgba(245, 158, 11, 0.2)' }}>
            <Clock size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Approved Credentials</span>
            <div className="admin-kpi-value">{stats.approved}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(16, 185, 129, 0.08)', color: 'var(--admin-success)', borderColor: 'rgba(16, 185, 129, 0.2)' }}>
            <ShieldCheck size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Rejected Credentials</span>
            <div className="admin-kpi-value">{stats.rejected}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(239, 68, 68, 0.08)', color: 'var(--admin-danger)', borderColor: 'rgba(239, 68, 68, 0.2)' }}>
            <ShieldAlert size={18} />
          </div>
        </div>
      </div>

      {/* ── Main Content Container ── */}
      <div className="admin-table-wrapper">

        {driverParam && (
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '0.75rem 1rem',
            background: 'rgba(244, 197, 34, 0.08)',
            border: '1px solid rgba(244, 197, 34, 0.25)',
            borderRadius: 8,
            marginBottom: '1rem'
          }}>
            <div style={{ fontSize: '0.85rem', color: '#fff' }}>
              Filtered by chauffeur: <strong style={{ color: 'var(--admin-primary)' }}>
                {groups.find(g => g.driver_id === driverParam)?.driver_name || 'Selected Chauffeur'}
              </strong>
            </div>
            <button
              className="admin-btn admin-btn-outline"
              style={{ padding: '4px 10px', fontSize: '0.75rem' }}
              onClick={() => setSearchParams({})}
            >
              Show All Chauffeurs
            </button>
          </div>
        )}
        
        {/* Filter Bar & Tabs */}
        <div className="admin-table-filter-bar" style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem', alignItems: 'stretch' }}>
          
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
            
            {/* Status Tabs */}
            <div className="admin-filter-tabs">
              <button 
                className={`admin-filter-tab ${statusFilter === 'all' ? 'active' : ''}`}
                onClick={() => setStatusFilter('all')}
              >
                All Documents <span className="admin-filter-count">{stats.totalDocs}</span>
              </button>
              <button 
                className={`admin-filter-tab ${statusFilter === 'pending' ? 'active' : ''}`}
                onClick={() => setStatusFilter('pending')}
              >
                Pending Review <span className="admin-filter-count">{stats.pending}</span>
              </button>
              <button 
                className={`admin-filter-tab ${statusFilter === 'approved' ? 'active' : ''}`}
                onClick={() => setStatusFilter('approved')}
              >
                Approved <span className="admin-filter-count">{stats.approved}</span>
              </button>
              <button 
                className={`admin-filter-tab ${statusFilter === 'rejected' ? 'active' : ''}`}
                onClick={() => setStatusFilter('rejected')}
              >
                Rejected <span className="admin-filter-count">{stats.rejected}</span>
              </button>
            </div>

            {/* Search Box */}
            <div className="admin-search-wrapper" style={{ minWidth: 260 }}>
              <Search size={15} style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)', color: '#71717a' }} />
              <input
                type="text"
                placeholder="Search chauffeur name..."
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

        {/* Content Body */}
        {loading ? (
          <div style={{ padding: '4rem', textAlign: 'center', color: '#a1a1aa' }}>
            <RotateCw size={24} className="admin-spin" style={{ margin: '0 auto 0.75rem', display: 'block', color: 'var(--admin-primary)' }} />
            Loading compliance registry...
          </div>
        ) : error ? (
          <div style={{ padding: '4rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem', fontSize: '0.9rem' }}>{error}</p>
            <button className="admin-btn" onClick={fetchDocuments}>Try Again</button>
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '4rem 1.5rem', color: '#71717a' }}>
            <FileCheck size={36} style={{ margin: '0 auto 0.75rem', opacity: 0.4 }} />
            <h3 style={{ margin: '0 0 0.4rem', color: '#fff', fontSize: '1rem' }}>No Compliance Records Found</h3>
            <p style={{ fontSize: '0.84rem', margin: 0 }}>
              {search ? `No chauffeurs matching "${search}" found.` : 'No document records match the selected filter.'}
            </p>
          </div>
        ) : (
          <div style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {filtered.map((group) => {
              const groupPendingCount = group.docs.filter((d) => d.status === 'pending').length;

              return (
                <div
                  key={group.driver_id}
                  className={`doc-compliance-group ${group.expanded ? 'expanded' : ''}`}
                >
                  <div className="doc-compliance-header" onClick={() => toggleExpand(group.driver_id)}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
                      <div className="admin-avatar-small" style={{ width: 36, height: 36, fontSize: '0.88rem' }}>
                        {group.driver_name.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <div style={{ fontWeight: 600, fontSize: '0.92rem', color: '#fff' }}>{group.driver_name}</div>
                        <div style={{ fontSize: '0.72rem', color: '#71717a' }}>
                          {group.docs.length} credential{group.docs.length !== 1 ? 's' : ''} on record
                        </div>
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      {groupPendingCount > 0 && (
                        <span className="admin-badge admin-badge-warning" style={{ fontSize: '0.68rem', padding: '2px 8px' }}>
                          {groupPendingCount} Pending Action
                        </span>
                      )}
                      <div className={`doc-chevron-icon ${group.expanded ? 'open' : ''}`}>
                        <ChevronDown size={18} />
                      </div>
                    </div>
                  </div>

                  {group.expanded && (
                    <div style={{ borderTop: '1px solid rgba(255, 255, 255, 0.05)', background: '#0e0e11' }}>
                      {group.docs.map((doc) => (
                        <div key={doc.id} className="doc-item-row" style={{ padding: '0.95rem 1.25rem', borderBottom: '1px solid rgba(255, 255, 255, 0.04)' }}>
                          <div className="doc-item-left">
                            <div>
                              <div style={{ fontWeight: 600, color: '#fff', fontSize: '0.88rem' }}>
                                {typeLabel(doc.type)}
                              </div>
                              <div style={{ fontSize: '0.75rem', color: '#71717a', marginTop: 3 }}>
                                <span>Submitted: {formatDate(doc.created_at)}</span>
                                <span style={{ margin: '0 6px' }}>·</span>
                                <span>Expires: {formatDate(doc.expires_at)}</span>
                              </div>
                              {doc.rejection_reason && (
                                <div style={{ fontSize: '0.75rem', color: '#fca5a5', marginTop: '0.35rem', background: 'rgba(239, 68, 68, 0.08)', padding: '0.35rem 0.65rem', borderRadius: 6, border: '1px solid rgba(239, 68, 68, 0.18)' }}>
                                  Reason for rejection: {doc.rejection_reason}
                                </div>
                              )}
                            </div>
                          </div>

                          <div className="doc-item-right" style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
                            {statusBadge(doc.status)}

                            {doc.file_url && (
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  openDocPreview(doc);
                                }}
                                className="admin-btn admin-btn-outline"
                                style={{ padding: '0.35rem 0.75rem', fontSize: '0.78rem' }}
                                title="Inspect document"
                              >
                                <Eye size={13} style={{ marginRight: 4 }} /> View
                              </button>
                            )}

                            {doc.status === 'pending' && (
                              <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleApprove(doc.id);
                                  }}
                                  disabled={actionLoading}
                                  className="admin-btn"
                                  style={{ padding: '0.35rem 0.75rem', fontSize: '0.78rem', background: 'var(--admin-success)', borderColor: 'var(--admin-success)', color: '#09090b' }}
                                  title="Approve Document"
                                >
                                  <CheckCircle size={13} style={{ marginRight: 4 }} /> Approve
                                </button>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleReject(doc.id);
                                  }}
                                  disabled={actionLoading}
                                  className="admin-btn admin-btn-outline"
                                  style={{ padding: '0.35rem 0.75rem', fontSize: '0.78rem', color: 'var(--admin-danger)', borderColor: 'rgba(239, 68, 68, 0.3)' }}
                                  title="Reject Document"
                                >
                                  <XCircle size={13} style={{ marginRight: 4 }} /> Reject
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



      {/* ── Document Inspection Slide-Over Drawer (Zero Modal) ── */}
      <AdminDrawer
        isOpen={!!previewDoc}
        onClose={() => {
          setPreviewDoc(null);
          setDiditData(null);
          setDiditError('');
          setRejectDocId(null);
        }}
        width={760}
        title={previewDoc ? typeLabel(previewDoc.type) : ''}
        subtitle={previewDoc ? `Submitted ${formatDate(previewDoc.created_at)}${previewDoc.expires_at ? ` · Expires ${formatDate(previewDoc.expires_at)}` : ''}` : ''}
        headerAction={previewDoc ? statusBadge(previewDoc.status) : undefined}
        footer={
          previewDoc?.status === 'pending' ? (
            <div style={{ display: 'flex', gap: 8, width: '100%', justifyContent: 'space-between', alignItems: 'center' }}>
              <button
                className="admin-btn admin-btn-outline"
                onClick={() => {
                  setPreviewDoc(null);
                  setRejectDocId(null);
                }}
              >
                Close
              </button>
              <div style={{ display: 'flex', gap: 8 }}>
                <button
                  onClick={() => handleReject(previewDoc.id)}
                  disabled={actionLoading}
                  className="admin-btn admin-btn-outline"
                  style={{ color: 'var(--admin-danger)', borderColor: 'rgba(239, 68, 68, 0.3)' }}
                >
                  <XCircle size={14} style={{ marginRight: 4 }} /> Reject Credential
                </button>
                <button
                  onClick={() => {
                    handleApprove(previewDoc.id);
                    setPreviewDoc(null);
                  }}
                  disabled={actionLoading}
                  className="admin-btn"
                  style={{ background: 'var(--admin-success)', borderColor: 'var(--admin-success)', color: '#09090b' }}
                >
                  <CheckCircle size={14} style={{ marginRight: 4 }} /> Approve Credential
                </button>
              </div>
            </div>
          ) : (
            <button
              className="admin-btn admin-btn-outline"
              onClick={() => {
                setPreviewDoc(null);
                setRejectDocId(null);
              }}
            >
              Close
            </button>
          )
        }
      >
        {previewDoc && (
          <div>
            {/* Inline Rejection Feedback Panel */}
            {rejectDocId ? (
              <div style={{ background: '#16161a', border: '1px solid rgba(239, 68, 68, 0.3)', borderRadius: 10, padding: '1rem', marginBottom: '1rem' }}>
                <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#ef4444', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: 6 }}>
                  Rejection Reason for Chauffeur
                </span>
                <p style={{ fontSize: '0.8rem', color: '#a1a1aa', margin: '0 0 0.5rem' }}>
                  Provide a note explaining why this credential was rejected so the chauffeur can re-upload:
                </p>
                <textarea
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  placeholder="e.g. Image blurry, expiration date passed, policy name does not match profile…"
                  rows={3}
                  className="admin-input"
                  style={{ width: '100%', resize: 'vertical' }}
                  autoFocus
                />
                <div style={{ display: 'flex', gap: 8, marginTop: 8, justifyContent: 'flex-end' }}>
                  <button className="admin-btn admin-btn-outline" onClick={() => setRejectDocId(null)}>
                    Cancel
                  </button>
                  <button className="admin-btn admin-btn-danger" onClick={confirmReject} disabled={actionLoading}>
                    Confirm Rejection
                  </button>
                </div>
              </div>
            ) : null}

            {previewDoc.file_url.startsWith('didit://') ? (
              diditLoading ? (
                <div style={{ padding: '4rem 2rem', textAlign: 'center', color: '#a1a1aa' }}>
                  <RotateCw size={28} className="admin-spin" style={{ margin: '0 auto 1rem', display: 'block', color: 'var(--admin-primary)' }} />
                  <p style={{ margin: 0, fontWeight: 600, color: '#fff' }}>Contacting Didit Compliance API…</p>
                  <p style={{ margin: '4px 0 0', fontSize: '0.8rem', color: '#71717a' }}>Querying biometric face match, passive liveness telemetry & session tokens</p>
                </div>
              ) : diditError ? (
                <div style={{ padding: '2.5rem', textAlign: 'center' }}>
                  <ShieldAlert size={36} color="#ef4444" style={{ margin: '0 auto 0.75rem', display: 'block' }} />
                  <p style={{ color: '#ef4444', fontWeight: 600, margin: '0 0 0.5rem' }}>Didit Telemetry Synchronization Failed</p>
                  <p style={{ color: '#a1a1aa', fontSize: '0.84rem', margin: '0 0 1rem', maxWidth: '420px', marginInline: 'auto' }}>{diditError}</p>
                  <button onClick={() => openDocPreview(previewDoc)} className="admin-btn" style={{ marginInline: 'auto' }}>
                    <RotateCw size={13} style={{ marginRight: 5 }} /> Retry Didit Sync
                  </button>
                </div>
              ) : diditData ? (
                (() => {
                  const session = diditData.session || diditData;
                  const idVerif = session?.id_verifications?.[0] || diditData?.id_verifications?.[0] || session?.id_verification;
                  const liveness = session?.liveness?.[0] || session?.liveness;
                  const faceMatch = session?.face_matches?.[0] || session?.face_match;

                  const gallery = [
                    (idVerif?.front_image || idVerif?.full_front_image) && {
                      title: `${idVerif.document_type || 'Identity Card'} (Front)`,
                      tag: 'Document Front',
                      url: idVerif.front_image || idVerif.full_front_image,
                    },
                    (idVerif?.back_image || idVerif?.full_back_image) && {
                      title: `${idVerif.document_type || 'Identity Card'} (Back)`,
                      tag: 'Document Back',
                      url: idVerif.back_image || idVerif.full_back_image,
                    },
                    idVerif?.portrait_image && {
                      title: 'ID Extracted Face Crop',
                      tag: 'Biometric Portrait',
                      url: idVerif.portrait_image,
                    },
                    (liveness?.reference_image || session?.selfie?.image) && {
                      title: 'Live Verification Selfie',
                      tag: liveness?.score !== undefined ? `Liveness ${liveness.score}%` : 'Live Capture',
                      url: liveness?.reference_image || (session?.selfie?.image?.startsWith('data:') ? session.selfie.image : `data:image/png;base64,${session?.selfie?.image}`),
                    },
                  ].filter(Boolean) as { title: string; tag: string; url: string }[];

                  const decisionStatus = session.status || 'In Review';
                  const isApproved = decisionStatus.toLowerCase() === 'approved';
                  const isInReview = decisionStatus.toLowerCase().includes('review');

                  return (
                    <div className="didit-telemetry-panel">
                      {/* Banner with Session Metadata */}
                      <div className="didit-meta-banner">
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4, flexWrap: 'wrap' }}>
                            <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--admin-primary)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                              DIDIT KYC DECISION
                            </span>
                            <span
                              className={`admin-badge ${isApproved ? 'admin-badge-success' : isInReview ? 'admin-badge-warning' : 'admin-badge-danger'}`}
                              style={{ fontSize: '0.7rem', padding: '2px 8px' }}
                            >
                              {decisionStatus}
                            </span>
                            {liveness?.score !== undefined && (
                              <span className="admin-badge admin-badge-success" style={{ fontSize: '0.7rem', padding: '2px 8px' }}>
                                Liveness: {liveness.score}%
                              </span>
                            )}
                            {faceMatch?.score !== undefined && (
                              <span className="admin-badge admin-badge-info" style={{ fontSize: '0.7rem', padding: '2px 8px' }}>
                                Face Match: {faceMatch.score}%
                              </span>
                            )}
                          </div>
                          <div style={{ fontFamily: 'monospace', fontSize: '0.76rem', color: '#a1a1aa' }}>
                            Session: {previewDoc.file_url.replace('didit://', '')}
                          </div>
                        </div>

                        <button
                          onClick={() => openDocPreview(previewDoc)}
                          className="admin-btn admin-btn-outline"
                          style={{ padding: '0.35rem 0.65rem', fontSize: '0.74rem' }}
                          title="Refresh verification telemetry"
                        >
                          <RotateCw size={12} style={{ marginRight: 4 }} /> Refresh
                        </button>
                      </div>

                      {/* Biometric & Document Scanned Images */}
                      {gallery.length > 0 ? (
                        <div>
                          <div style={{ fontSize: '0.78rem', fontWeight: 700, color: '#fff', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.65rem', display: 'flex', alignItems: 'center', gap: 6 }}>
                            <FileCheck size={14} style={{ color: 'var(--admin-primary)' }} />
                            Scanned Documents & Biometrics ({gallery.length})
                          </div>
                          <div className="didit-gallery-grid">
                            {gallery.map((img, idx) => (
                              <div key={idx} className="didit-gallery-card">
                                <div className="didit-gallery-card-header">
                                  <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: '140px' }}>
                                    {img.title}
                                  </span>
                                  <span style={{ fontSize: '0.68rem', color: 'var(--admin-primary)', background: 'rgba(244, 197, 34, 0.1)', padding: '1px 6px', borderRadius: 4 }}>
                                    {img.tag}
                                  </span>
                                </div>
                                <a
                                  href={img.url}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="didit-gallery-img-wrap"
                                  title="Click to view full resolution image in new tab"
                                >
                                  <img src={img.url} alt={img.title} />
                                  <div className="didit-gallery-hover-overlay">
                                    <ExternalLink size={16} />
                                    <span>View Full Resolution</span>
                                  </div>
                                </a>
                              </div>
                            ))}
                          </div>
                        </div>
                      ) : (
                        <div style={{ background: '#16161a', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10, padding: '1.25rem', textAlign: 'center', color: '#a1a1aa', fontSize: '0.84rem' }}>
                          No photographic assets recorded for this decision session yet.
                        </div>
                      )}

                      {/* Extracted Intelligence & OCR Table */}
                      <div>
                        <div style={{ fontSize: '0.78rem', fontWeight: 700, color: '#fff', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.65rem', display: 'flex', alignItems: 'center', gap: 6 }}>
                          <UserCheck size={14} style={{ color: 'var(--admin-primary)' }} />
                          Verified Identity Credentials (OCR Extracted)
                        </div>
                        <div className="didit-details-grid">
                          <div className="didit-detail-item">
                            <span className="didit-detail-label">Legal Name</span>
                            <span className="didit-detail-value" style={{ fontWeight: 600, color: '#fff' }}>
                              {idVerif?.full_name || `${idVerif?.first_name || ''} ${idVerif?.last_name || ''}`.trim() || '—'}
                            </span>
                          </div>

                          <div className="didit-detail-item">
                            <span className="didit-detail-label">Document Number</span>
                            <span className="didit-detail-value" style={{ fontFamily: 'monospace', color: 'var(--admin-primary)' }}>
                              {idVerif?.document_number || '—'}
                            </span>
                          </div>

                          <div className="didit-detail-item">
                            <span className="didit-detail-label">Document Classification</span>
                            <span className="didit-detail-value">
                              {idVerif?.document_type ? `${idVerif.document_type} (${idVerif.document_subtype || 'Standard'})` : 'Identity Document'}
                            </span>
                          </div>

                          <div className="didit-detail-item">
                            <span className="didit-detail-label">Issuing Authority</span>
                            <span className="didit-detail-value">
                              {idVerif?.issuing_state_name ? `${idVerif.issuing_state_name} (${idVerif.issuing_state || ''})` : idVerif?.issuing_state || '—'}
                            </span>
                          </div>

                          <div className="didit-detail-item">
                            <span className="didit-detail-label">Date of Birth / Age</span>
                            <span className="didit-detail-value">
                              {idVerif?.date_of_birth ? `${idVerif.date_of_birth} ${idVerif.age ? `(Age ${idVerif.age})` : ''}` : '—'}
                            </span>
                          </div>

                          <div className="didit-detail-item">
                            <span className="didit-detail-label">Passive Liveness Status</span>
                            <span className="didit-detail-value" style={{ color: liveness?.status === 'Approved' ? '#4ade80' : '#facc15' }}>
                              {liveness ? `${liveness.status} (Score: ${liveness.score}%)` : '—'}
                            </span>
                          </div>

                          <div className="didit-detail-item">
                            <span className="didit-detail-label">Face Match Similarity</span>
                            <span className="didit-detail-value">
                              {faceMatch ? `${faceMatch.score}% (${faceMatch.status})` : '—'}
                            </span>
                          </div>

                          <div className="didit-detail-item">
                            <span className="didit-detail-label">Verification Mode</span>
                            <span className="didit-detail-value">
                              Didit v3 Automated Compliance
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })()
              ) : null
            ) : (
              <div style={{ textAlign: 'center' }}>
                <a
                  href={previewDoc.file_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{ position: 'relative', display: 'inline-block', maxWidth: '100%' }}
                  title="Click to view full size in new tab"
                >
                  <img
                    src={previewDoc.file_url}
                    alt={typeLabel(previewDoc.type)}
                    style={{ maxWidth: '100%', maxHeight: '480px', objectFit: 'contain', borderRadius: 10, border: '1px solid rgba(255,255,255,0.08)' }}
                  />
                  <div style={{ marginTop: '0.65rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, fontSize: '0.78rem', color: 'var(--admin-primary)' }}>
                    <ExternalLink size={13} />
                    <span>Open high-resolution file in new tab</span>
                  </div>
                </a>
              </div>
            )}
          </div>
        )}
      </AdminDrawer>

    </div>
  );
}
