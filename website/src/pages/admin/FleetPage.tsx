import { useEffect, useState, useMemo, useRef } from 'react';
import { Search, Download, Plus, Pencil, Trash2, X, Check, Star, Upload } from 'lucide-react';
import { supabase } from '../../lib/supabase';

const MAX_FEATURED = 6;

const CLOUD_NAME = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME || '';
const UPLOAD_PRESET = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET || '';

interface FleetCar {
  id: string;
  make: string;
  model: string;
  year: number;
  image_url: string | null;
  features: string | null;
  chauffeur_count: number;
  is_featured: boolean;
  created_at: string;
}

interface VehicleRequest {
  id: string;
  chauffeur_id: string;
  make: string;
  model: string;
  year: number;
  color: string;
  license_plate: string;
  status: string;
  admin_note: string | null;
  created_at: string;
  chauffeur_name: string;
}

const emptyCar = { make: '', model: '', year: new Date().getFullYear(), image_url: '', features: '' };

function compressImage(file: File, maxSize = 800, quality = 0.8): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      URL.revokeObjectURL(url);
      const size = Math.min(img.width, img.height);
      const sx = (img.width - size) / 2;
      const sy = (img.height - size) / 2;
      const canvas = document.createElement('canvas');
      canvas.width = maxSize;
      canvas.height = maxSize;
      const ctx = canvas.getContext('2d')!;
      ctx.drawImage(img, sx, sy, size, size, 0, 0, maxSize, maxSize);
      canvas.toBlob(
        (blob) => {
          if (blob) resolve(blob);
          else reject(new Error('Compression failed'));
        },
        'image/jpeg',
        quality
      );
    };
    img.onerror = () => reject(new Error('Failed to load image'));
    img.src = url;
  });
}

async function uploadToCloudinary(file: File): Promise<string | null> {
  if (!CLOUD_NAME || !UPLOAD_PRESET) {
    alert('Cloudinary not configured. Add VITE_CLOUDINARY_CLOUD_NAME and VITE_CLOUDINARY_UPLOAD_PRESET to .env');
    return null;
  }
  const compressed = await compressImage(file);
  const formData = new FormData();
  formData.append('file', compressed, file.name);
  formData.append('upload_preset', UPLOAD_PRESET);

  const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`, {
    method: 'POST',
    body: formData,
  });
  if (!res.ok) return null;
  const data = await res.json();
  return data.secure_url || null;
}

export default function FleetPage() {
  const [activeTab, setActiveTab] = useState<'fleet' | 'requests'>('fleet');
  const [fleetCars, setFleetCars] = useState<FleetCar[]>([]);
  const [requests, setRequests] = useState<VehicleRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);
  const [editCar, setEditCar] = useState<FleetCar | null>(null);
  const [form, setForm] = useState(emptyCar);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [rejectNote, setRejectNote] = useState('');
  const [rejectingId, setRejectingId] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      const { data: cars, error: carsError } = await supabase
        .from('fleet_cars')
        .select('id, make, model, year, image_url, features, is_featured, created_at')
        .is('deleted_at', null)
        .order('is_featured', { ascending: false })
        .order('created_at', { ascending: false });

      if (carsError) throw carsError;

      const carIds = (cars || []).map((c) => c.id);
      const { data: assignedVehicles } = await supabase
        .from('vehicles')
        .select('fleet_car_id')
        .not('fleet_car_id', 'is', null)
        .in('fleet_car_id', carIds.length > 0 ? carIds : ['00000000-0000-0000-0000-000000000000']);

      const chauffeurCountMap = new Map<string, number>();
      assignedVehicles?.forEach((v) => {
        if (v.fleet_car_id) {
          chauffeurCountMap.set(v.fleet_car_id, (chauffeurCountMap.get(v.fleet_car_id) || 0) + 1);
        }
      });

      setFleetCars(
        (cars || []).map((c) => ({
          ...c,
          chauffeur_count: chauffeurCountMap.get(c.id) || 0,
        }))
      );

      const { data: reqs, error: reqsError } = await supabase
        .from('vehicle_requests')
        .select('id, chauffeur_id, make, model, year, color, license_plate, status, admin_note, created_at')
        .eq('status', 'pending')
        .order('created_at', { ascending: false });

      if (reqsError) throw reqsError;

      const chauffeurIds = [...new Set((reqs || []).map((r) => r.chauffeur_id))];
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .in('id', chauffeurIds.length > 0 ? chauffeurIds : ['00000000-0000-0000-0000-000000000000']);

      const profileMap = new Map<string, { first_name: string | null; last_name: string | null; email: string }>();
      profiles?.forEach((p) => profileMap.set(p.id, p));

      setRequests(
        (reqs || []).map((r) => {
          const p = profileMap.get(r.chauffeur_id);
          return {
            ...r,
            chauffeur_name: p
              ? [p.first_name, p.last_name].filter(Boolean).join(' ') || p.email
              : 'Unknown',
          };
        })
      );
    } catch (err) {
      setError('Failed to load fleet data');
    } finally {
      setLoading(false);
    }
  };

  const featuredCount = fleetCars.filter((c) => c.is_featured).length;

  const filteredCars = useMemo(() => {
    if (!search.trim()) return fleetCars;
    const q = search.toLowerCase();
    return fleetCars.filter(
      (c) =>
        c.make.toLowerCase().includes(q) ||
        c.model.toLowerCase().includes(q)
    );
  }, [fleetCars, search]);

  const filteredRequests = useMemo(() => {
    if (!search.trim()) return requests;
    const q = search.toLowerCase();
    return requests.filter(
      (r) =>
        r.make.toLowerCase().includes(q) ||
        r.model.toLowerCase().includes(q) ||
        r.license_plate.toLowerCase().includes(q) ||
        r.chauffeur_name.toLowerCase().includes(q)
    );
  }, [requests, search]);

  const openAddModal = () => {
    setEditCar(null);
    setForm(emptyCar);
    setShowAddModal(true);
  };

  const openEditModal = (car: FleetCar) => {
    setEditCar(car);
    setForm({ make: car.make, model: car.model, year: car.year, image_url: car.image_url || '', features: car.features || '' });
    setShowAddModal(true);
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      setError('Please select an image file');
      return;
    }
    setUploading(true);
    try {
      const url = await uploadToCloudinary(file);
      if (url) {
        setForm((prev) => ({ ...prev, image_url: url }));
      } else {
        setError('Failed to upload image');
      }
    } catch (err) {
      setError('Failed to upload image');
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleSave = async () => {
    if (!form.make || !form.model || !form.year) return;
    setSaving(true);
    try {
      const payload = {
        make: form.make,
        model: form.model,
        year: form.year,
        image_url: form.image_url || null,
        features: form.features || '',
      };

      if (editCar) {
        const { error } = await supabase
          .from('fleet_cars')
          .update(payload)
          .eq('id', editCar.id);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('fleet_cars')
          .insert(payload);
        if (error) throw error;
      }
      setShowAddModal(false);
      fetchData();
    } catch (err: any) {
      setError(err.message || 'Failed to save car');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this fleet car?')) return;
    try {
      const { error } = await supabase
        .from('fleet_cars')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);
      if (error) throw error;
      fetchData();
    } catch (err: any) {
      setError(err.message || 'Failed to delete car');
    }
  };

  const handleToggleFeatured = async (car: FleetCar) => {
    if (!car.is_featured && featuredCount >= MAX_FEATURED) {
      setError(`Maximum ${MAX_FEATURED} cars can be featured. Unfeature one first.`);
      return;
    }
    try {
      const { error } = await supabase
        .from('fleet_cars')
        .update({ is_featured: !car.is_featured })
        .eq('id', car.id);
      if (error) throw error;
      fetchData();
    } catch (err: any) {
      setError(err.message || 'Failed to update featured status');
    }
  };

  const handleApproveRequest = async (req: VehicleRequest) => {
    try {
      const { error: updateError } = await supabase
        .from('vehicle_requests')
        .update({ status: 'approved', reviewed_at: new Date().toISOString() })
        .eq('id', req.id);
      if (updateError) throw updateError;

      const { error: insertError } = await supabase
        .from('fleet_cars')
        .insert({ make: req.make, model: req.model, year: req.year });
      if (insertError) throw insertError;

      fetchData();
    } catch (err: any) {
      setError(err.message || 'Failed to approve request');
    }
  };

  const handleRejectRequest = async (reqId: string) => {
    try {
      const { error } = await supabase
        .from('vehicle_requests')
        .update({ status: 'rejected', admin_note: rejectNote || null, reviewed_at: new Date().toISOString() })
        .eq('id', reqId);
      if (error) throw error;
      setRejectingId(null);
      setRejectNote('');
      fetchData();
    } catch (err: any) {
      setError(err.message || 'Failed to reject request');
    }
  };

  const exportCSV = () => {
    if (activeTab === 'fleet') {
      const headers = ['Make', 'Model', 'Year', 'Chauffeurs', 'Featured'];
      const rows = filteredCars.map((c) => [c.make, c.model, c.year, c.chauffeur_count, c.is_featured ? 'Yes' : 'No']);
      const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `fleet_cars_${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } else {
      const headers = ['Chauffeur', 'Make', 'Model', 'Year', 'License Plate', 'Status'];
      const rows = filteredRequests.map((r) => [r.chauffeur_name, r.make, r.model, r.year, r.license_plate, r.status]);
      const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `vehicle_requests_${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    }
  };

  const formatDate = (iso: string) =>
    new Date(iso).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Fleet Management</h1>
          <p>Manage fleet vehicles and chauffeur car requests</p>
        </div>
        <div className="admin-page-header-actions">
          {activeTab === 'fleet' && (
            <button className="admin-btn" onClick={openAddModal}>
              <Plus size={16} />
              Add Car
            </button>
          )}
          <button className="admin-btn" onClick={exportCSV}>
            <Download size={16} />
            Export CSV
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1.5rem' }}>
        <button
          className={`admin-btn ${activeTab === 'fleet' ? '' : 'admin-btn-outline'}`}
          onClick={() => { setActiveTab('fleet'); setSearch(''); }}
        >
          Fleet Cars ({fleetCars.length})
        </button>
        <button
          className={`admin-btn ${activeTab === 'requests' ? '' : 'admin-btn-outline'}`}
          onClick={() => { setActiveTab('requests'); setSearch(''); }}
          style={{ position: 'relative' }}
        >
          Requests ({requests.length})
          {requests.length > 0 && (
            <span style={{
              position: 'absolute', top: -4, right: -4, width: 18, height: 18,
              borderRadius: '50%', background: '#ef4444', color: '#fff',
              fontSize: '10px', fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {requests.length}
            </span>
          )}
        </button>
      </div>

      {/* Featured limit indicator */}
      {activeTab === 'fleet' && (
        <div style={{ marginBottom: '1rem', fontSize: '0.8rem', color: '#a1a1aa' }}>
          Featured on landing page: <span style={{ color: featuredCount >= MAX_FEATURED ? '#ef4444' : '#22c55e', fontWeight: 600 }}>{featuredCount}/{MAX_FEATURED}</span>
        </div>
      )}

      <div className="admin-table-wrapper">
        <div className="admin-table-filter-bar">
          <div className="admin-search-wrapper">
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input
              type="text"
              placeholder={activeTab === 'fleet' ? 'Search cars...' : 'Search requests...'}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="admin-search-input"
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>Loading fleet data...</div>
        ) : error ? (
          <div style={{ padding: '3rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error}</p>
            <button className="admin-btn" onClick={() => { setError(null); setLoading(true); fetchData(); }}>Try Again</button>
          </div>
        ) : activeTab === 'fleet' ? (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col"></th>
                <th scope="col">Vehicle</th>
                <th scope="col">Features</th>
                <th scope="col">Chauffeurs</th>
                <th scope="col">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredCars.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No cars match your search.' : 'No fleet cars yet. Add one to get started.'}
                  </td>
                </tr>
              ) : (
                filteredCars.map((c) => (
                  <tr key={c.id}>
                    <td style={{ width: 40 }}>
                      <button
                        onClick={() => handleToggleFeatured(c)}
                        title={c.is_featured ? 'Remove from landing page' : 'Feature on landing page'}
                        style={{
                          background: 'none', border: 'none', cursor: 'pointer', padding: '2px',
                          opacity: !c.is_featured && featuredCount >= MAX_FEATURED ? 0.3 : 1,
                        }}
                      >
                        <Star
                          size={18}
                          fill={c.is_featured ? '#eab308' : 'none'}
                          color={c.is_featured ? '#eab308' : '#71717a'}
                        />
                      </button>
                    </td>
                    <td data-label="Vehicle">
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        {c.image_url ? (
                          <img src={c.image_url} alt="" style={{ width: 48, height: 48, borderRadius: 8, objectFit: 'cover', flexShrink: 0 }} />
                        ) : (
                          <div style={{ width: 48, height: 48, borderRadius: 8, background: '#27272a', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#71717a', fontSize: '10px', flexShrink: 0 }}>No img</div>
                        )}
                        <div>
                          <div style={{ fontWeight: 500 }}>{c.make} {c.model}</div>
                          <span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>{c.year} - Black</span>
                        </div>
                      </div>
                    </td>
                    <td data-label="Features">
                      <div style={{ fontSize: '0.8rem', color: '#a1a1aa', maxWidth: 200, whiteSpace: 'pre-line' }}>
                        {c.features || '—'}
                      </div>
                    </td>
                    <td data-label="Chauffeurs">
                      {c.chauffeur_count > 0 ? (
                        <span className="admin-badge admin-badge-success">{c.chauffeur_count} Active</span>
                      ) : (
                        <span className="admin-badge admin-badge-info">No Chauffeurs</span>
                      )}
                    </td>
                    <td data-label="Actions">
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        <button
                          className="admin-btn admin-btn-outline"
                          onClick={() => openEditModal(c)}
                          style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem' }}
                        >
                          <Pencil size={14} />
                        </button>
                        <button
                          className="admin-btn admin-btn-outline"
                          onClick={() => handleDelete(c.id)}
                          style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem', borderColor: '#ef4444', color: '#ef4444' }}
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Chauffeur</th>
                <th scope="col">Vehicle</th>
                <th scope="col">License Plate</th>
                <th scope="col">Requested</th>
                <th scope="col">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredRequests.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No requests match your search.' : 'No pending vehicle requests.'}
                  </td>
                </tr>
              ) : (
                filteredRequests.map((r) => (
                  <tr key={r.id}>
                    <td data-label="Chauffeur"><div style={{ fontWeight: 500 }}>{r.chauffeur_name}</div></td>
                    <td data-label="Vehicle">
                      <div style={{ fontWeight: 500 }}>{r.make} {r.model}</div>
                      <span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>{r.year} {r.color}</span>
                    </td>
                    <td data-label="License Plate"><div style={{ fontFamily: 'monospace' }}>{r.license_plate}</div></td>
                    <td data-label="Requested">{formatDate(r.created_at)}</td>
                    <td data-label="Actions">
                      {rejectingId === r.id ? (
                        <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'center' }}>
                          <input
                            className="admin-input"
                            placeholder="Note (optional)"
                            value={rejectNote}
                            onChange={(e) => setRejectNote(e.target.value)}
                            style={{ width: 140, padding: '4px 8px', fontSize: '0.75rem' }}
                          />
                          <button
                            className="admin-btn"
                            onClick={() => handleRejectRequest(r.id)}
                            style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem', background: '#ef4444' }}
                          >
                            <Check size={14} />
                          </button>
                          <button
                            className="admin-btn admin-btn-outline"
                            onClick={() => { setRejectingId(null); setRejectNote(''); }}
                            style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem' }}
                          >
                            <X size={14} />
                          </button>
                        </div>
                      ) : (
                        <div style={{ display: 'flex', gap: '0.5rem' }}>
                          <button
                            className="admin-btn"
                            onClick={() => handleApproveRequest(r)}
                            style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem' }}
                          >
                            <Check size={14} /> Approve
                          </button>
                          <button
                            className="admin-btn admin-btn-outline"
                            onClick={() => setRejectingId(r.id)}
                            style={{ padding: '0.35rem 0.6rem', fontSize: '0.75rem', borderColor: '#ef4444', color: '#ef4444' }}
                          >
                            <X size={14} /> Reject
                          </button>
                        </div>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>

      {/* Add/Edit Modal */}
      {showAddModal && (
        <div className="admin-modal-overlay" onClick={() => setShowAddModal(false)}>
          <div className="admin-modal" onClick={(e) => e.stopPropagation()} style={{ width: 520, maxHeight: '90vh', overflowY: 'auto' }}>
            <h2 style={{ marginBottom: '1rem' }}>{editCar ? 'Edit Fleet Car' : 'Add Fleet Car'}</h2>
            <div className="form-group">
              <label>Make</label>
              <input
                className="admin-input"
                value={form.make}
                onChange={(e) => setForm({ ...form, make: e.target.value })}
                placeholder="e.g. GMC"
              />
            </div>
            <div className="form-group">
              <label>Model</label>
              <input
                className="admin-input"
                value={form.model}
                onChange={(e) => setForm({ ...form, model: e.target.value })}
                placeholder="e.g. Yukon"
              />
            </div>
            <div className="form-group">
              <label>Year</label>
              <input
                className="admin-input"
                type="number"
                value={form.year}
                onChange={(e) => setForm({ ...form, year: parseInt(e.target.value) || 0 })}
              />
            </div>
            <div className="form-group">
              <label>Image</label>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleImageUpload}
                style={{ display: 'none' }}
              />
              {form.image_url ? (
                <div style={{ position: 'relative', marginBottom: '0.75rem' }}>
                  <img
                    src={form.image_url}
                    alt=""
                    style={{
                      width: '100%',
                      aspectRatio: '1',
                      maxHeight: 160,
                      borderRadius: 12,
                      objectFit: 'cover',
                      border: '1px solid rgba(255,255,255,0.1)',
                    }}
                  />
                  <button
                    onClick={() => setForm((prev) => ({ ...prev, image_url: '' }))}
                    style={{
                      position: 'absolute', top: 8, right: 8,
                      width: 28, height: 28, borderRadius: '50%',
                      background: 'rgba(0,0,0,0.7)', border: 'none',
                      color: '#fff', cursor: 'pointer',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}
                  >
                    <X size={14} />
                  </button>
                  <button
                    className="admin-btn admin-btn-outline"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={uploading}
                    style={{ position: 'absolute', bottom: 8, right: 8, fontSize: '0.75rem', padding: '0.3rem 0.6rem' }}
                  >
                    <Upload size={12} /> Replace
                  </button>
                </div>
              ) : (
                <button
                  className="admin-btn admin-btn-outline"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploading}
                  style={{ width: '100%', justifyContent: 'center', padding: '2rem', borderStyle: 'dashed' }}
                >
                  <Upload size={20} />
                  {uploading ? 'Uploading...' : 'Click to upload image'}
                </button>
              )}
            </div>
            <div className="form-group">
              <label>Features (one per line)</label>
              <textarea
                className="admin-input"
                value={form.features}
                onChange={(e) => setForm({ ...form, features: e.target.value })}
                placeholder={"Three row SUV\n16-way power front seats with massage\nAir ride adaptive suspension"}
                rows={3}
                style={{ resize: 'vertical', whiteSpace: 'pre' }}
              />
            </div>
            <p style={{ fontSize: '0.75rem', color: '#71717a', margin: '0 0 1rem' }}>Color is always Black. Chauffeur adds license plate after selecting.</p>
            <div className="form-actions">
              <button className="admin-btn admin-btn-outline" onClick={() => setShowAddModal(false)}>
                Cancel
              </button>
              <button className="admin-btn" onClick={handleSave} disabled={saving || uploading}>
                {saving ? 'Saving...' : editCar ? 'Save Changes' : 'Add Car'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
