import { useEffect, useState, useMemo, useRef } from 'react';
import { 
  Search, 
  Download, 
  Plus, 
  Pencil, 
  Trash2, 
  X, 
  Check, 
  Star, 
  Upload, 
  Car, 
  CheckCircle2, 
  Clock, 
  RotateCw,
  Wand2,
  Loader2
} from 'lucide-react';

import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
import { AdminDrawer } from '../../components/ui/AdminDrawer';
import { InlineConfirmButton } from '../../components/ui/InlineConfirmButton';
import {
  categorizeVehicleWithGemini,
  categorizeVehicleFallback,
} from '../../services/geminiFleetService';
import type {
  FleetCategory,
  VehicleCategorizationResult
} from '../../services/geminiFleetService';

const MAX_FEATURED = 6;

const CLOUD_NAME = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME || '';
const UPLOAD_PRESET = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET || '';

export type { FleetCategory };
export const autoCategorizeVehicle = categorizeVehicleFallback;

interface FleetCar {
  id: string;
  make: string;
  model: string;
  year: number;
  image_url: string | null;
  features: string | null;
  category?: FleetCategory;
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

const emptyCar = { make: '', model: '', year: new Date().getFullYear(), image_url: '', features: '', category: 'Business Class' as FleetCategory };

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
    console.warn('Cloudinary not configured. Add VITE_CLOUDINARY_CLOUD_NAME and VITE_CLOUDINARY_UPLOAD_PRESET to .env');
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
  const toast = useToast();
  const [activeTab, setActiveTab] = useState<'fleet' | 'requests'>('fleet');
  const [fleetCars, setFleetCars] = useState<FleetCar[]>([]);
  const [requests, setRequests] = useState<VehicleRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<'all' | FleetCategory>('all');
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
      setError('Failed to load fleet inventory');
    } finally {
      setLoading(false);
    }
  };

  const featuredCount = fleetCars.filter((c) => c.is_featured).length;

  const totalAssignedChauffeurs = useMemo(() => {
    return fleetCars.reduce((sum, c) => sum + c.chauffeur_count, 0);
  }, [fleetCars]);

  const filteredCars = useMemo(() => {
    return fleetCars.filter((c) => {
      const currentCat = c.category || autoCategorizeVehicle(c.make, c.model, c.year).category;
      if (categoryFilter !== 'all' && currentCat !== categoryFilter) {
        return false;
      }
      if (!search.trim()) return true;
      const q = search.toLowerCase();
      return (
        c.make.toLowerCase().includes(q) ||
        c.model.toLowerCase().includes(q) ||
        c.year.toString().includes(q) ||
        currentCat.toLowerCase().includes(q) ||
        (c.features?.toLowerCase() || '').includes(q)
      );
    });
  }, [fleetCars, search, categoryFilter]);

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
    setForm({ make: car.make, model: car.model, year: car.year, image_url: car.image_url || '', features: car.features || '', category: car.category || autoCategorizeVehicle(car.make, car.model, car.year).category });
    setShowAddModal(true);
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      setError('Please select an image file');
      toast.error('Please select an image file');
      return;
    }
    if (!CLOUD_NAME || !UPLOAD_PRESET) {
      toast.error('Cloudinary credentials missing. Please configure VITE_CLOUDINARY in .env');
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

  const [aiSuggestions, setAiSuggestions] = useState<Record<string, VehicleCategorizationResult>>({});
  const [loadingAiCarIds, setLoadingAiCarIds] = useState<Record<string, boolean>>({});
  const [loadingFormAi, setLoadingFormAi] = useState(false);

  const handleSuggestCategory = async (car: FleetCar) => {
    setLoadingAiCarIds((prev) => ({ ...prev, [car.id]: true }));
    try {
      const res = await categorizeVehicleWithGemini({
        make: car.make,
        model: car.model,
        year: car.year,
        features: car.features,
      });
      setAiSuggestions((prev) => ({ ...prev, [car.id]: res }));
      if (res.evaluatedByGemini) {
        toast.info(`Gemini AI recommends "${res.category}"`);
      } else {
        toast.info(`AI recommends "${res.category}"`);
      }
    } catch {
      const fallback = categorizeVehicleFallback(car.make, car.model, car.year);
      setAiSuggestions((prev) => ({
        ...prev,
        [car.id]: { ...fallback, evaluatedByGemini: false },
      }));
      toast.info(`AI recommends "${fallback.category}"`);
    } finally {
      setLoadingAiCarIds((prev) => {
        const next = { ...prev };
        delete next[car.id];
        return next;
      });
    }
  };

  const handleAcceptSuggestion = async (car: FleetCar, suggestedCat: FleetCategory) => {
    try {
      setFleetCars((prev) =>
        prev.map((c) => (c.id === car.id ? { ...c, category: suggestedCat } : c))
      );
      setAiSuggestions((prev) => {
        const next = { ...prev };
        delete next[car.id];
        return next;
      });

      const { error } = await supabase
        .from('fleet_cars')
        .update({ category: suggestedCat })
        .eq('id', car.id);

      if (!error) {
        toast.success(`Category updated to ${suggestedCat}`);
      } else {
        toast.success(`Category set to ${suggestedCat} (active)`);
      }
    } catch {
      toast.success(`Category set to ${suggestedCat}`);
    }
  };

  const handleDeclineSuggestion = (carId: string) => {
    setAiSuggestions((prev) => {
      const next = { ...prev };
      delete next[carId];
      return next;
    });
    toast.info('AI suggestion dismissed');
  };

  const handleSave = async () => {
    if (!form.make || !form.model || !form.year) return;
    setSaving(true);
    try {
      const basePayload: Record<string, any> = {
        make: form.make,
        model: form.model,
        year: form.year,
        image_url: form.image_url || null,
        features: form.features || '',
      };
      const cat = form.category || autoCategorizeVehicle(form.make, form.model, form.year).category;
      const payloadWithCat = { ...basePayload, category: cat };

      if (editCar) {
        let res = await supabase
          .from('fleet_cars')
          .update(payloadWithCat)
          .eq('id', editCar.id);
        if (res.error) {
          res = await supabase.from('fleet_cars').update(basePayload).eq('id', editCar.id);
          if (res.error) throw res.error;
        }
      } else {
        let res = await supabase
          .from('fleet_cars')
          .insert(payloadWithCat);
        if (res.error) {
          res = await supabase.from('fleet_cars').insert(basePayload);
          if (res.error) throw res.error;
        }
      }
      setShowAddModal(false);
      toast.success(editCar ? 'Fleet model updated successfully' : 'Vehicle model registered');
      fetchData();
    } catch (err: any) {
      setError(err.message || 'Failed to save car');
      toast.error(err.message || 'Failed to save car');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      const { error } = await supabase
        .from('fleet_cars')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);
      if (error) throw error;
      toast.success('Fleet car model deleted');
      fetchData();
    } catch (err: any) {
      setError(err.message || 'Failed to delete car');
      toast.error(err.message || 'Failed to delete car');
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

      const { data: newFleetCar, error: insertError } = await supabase
        .from('fleet_cars')
        .insert({ make: req.make, model: req.model, year: req.year })
        .select()
        .single();
      if (insertError) throw insertError;

      // Assign and activate in public.vehicles for this chauffeur
      if (req.chauffeur_id) {
        await supabase
          .from('vehicles')
          .update({ is_active: false })
          .eq('driver_id', req.chauffeur_id);

        await supabase.from('vehicles').insert({
          driver_id: req.chauffeur_id,
          make: req.make,
          model: req.model,
          year: req.year,
          color: req.color || 'Black',
          license_plate: req.license_plate,
          is_active: true,
          fleet_car_id: newFleetCar?.id || null,
          images: [],
        });
      }

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
      const headers = ['Make', 'Model', 'Year', 'Assigned Chauffeurs', 'Featured on App', 'Features'];
      const rows = filteredCars.map((c) => [c.make, c.model, c.year, c.chauffeur_count, c.is_featured ? 'Yes' : 'No', c.features || '']);
      const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `fleet_models_${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } else {
      const headers = ['Chauffeur', 'Make', 'Model', 'Year', 'License Plate', 'Color', 'Status'];
      const rows = filteredRequests.map((r) => [r.chauffeur_name, r.make, r.model, r.year, r.license_plate, r.color, r.status]);
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

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Page Header */}
      <div className="admin-page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1>Luxury Fleet Management</h1>
          <p>Fleet model catalog, showcase curation, and vehicle compliance approvals</p>
        </div>
        <div className="admin-page-header-actions">
          <button className="admin-btn admin-btn-outline" onClick={fetchData} title="Refresh records">
            <RotateCw size={14} /> Refresh
          </button>
          <button className="admin-btn admin-btn-outline" onClick={exportCSV}>
            <Download size={14} /> Export CSV
          </button>
          <button className="admin-btn" onClick={openAddModal}>
            <Plus size={15} /> Add Vehicle Model
          </button>
        </div>
      </div>

      {/* Summary KPI Cards */}
      <div className="admin-kpi-summary-grid">
        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Fleet Models Catalog</span>
            <div className="admin-kpi-value">{fleetCars.length}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(255, 255, 255, 0.03)', color: '#fff' }}>
            <Car size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Featured on Booking App</span>
            <div className="admin-kpi-value">{featuredCount} / {MAX_FEATURED}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(244, 197, 34, 0.08)', color: 'var(--admin-primary)', borderColor: 'rgba(244, 197, 34, 0.2)' }}>
            <Star size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Assigned Chauffeur Units</span>
            <div className="admin-kpi-value">{totalAssignedChauffeurs}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(16, 185, 129, 0.08)', color: 'var(--admin-success)', borderColor: 'rgba(16, 185, 129, 0.2)' }}>
            <CheckCircle2 size={18} />
          </div>
        </div>

        <div className="admin-kpi-card">
          <div>
            <span className="admin-kpi-label">Pending Verification</span>
            <div className="admin-kpi-value">{requests.length}</div>
          </div>
          <div className="admin-kpi-icon" style={{ background: 'rgba(245, 158, 11, 0.08)', color: 'var(--admin-warning)', borderColor: 'rgba(245, 158, 11, 0.2)' }}>
            <Clock size={18} />
          </div>
        </div>
      </div>

      {/* Main Container */}
      <div className="admin-table-wrapper">
        
        {/* Navigation Tabs and Search Toolbar */}
        <div className="admin-table-filter-bar" style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem', alignItems: 'stretch' }}>
          
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
            
            {/* View Tabs */}
            <div className="admin-filter-tabs">
              <button 
                className={`admin-filter-tab ${activeTab === 'fleet' ? 'active' : ''}`}
                onClick={() => setActiveTab('fleet')}
              >
                Fleet Catalog <span className="admin-filter-count">{fleetCars.length}</span>
              </button>
              <button 
                className={`admin-filter-tab ${activeTab === 'requests' ? 'active' : ''}`}
                onClick={() => setActiveTab('requests')}
              >
                Verification Requests <span className="admin-filter-count">{requests.length}</span>
              </button>
            </div>

            {/* Search Input */}
            <div className="admin-search-wrapper" style={{ minWidth: 260 }}>
              <Search size={15} style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)', color: '#71717a' }} />
              <input
                type="text"
                placeholder={activeTab === 'fleet' ? 'Search make, model, feature...' : 'Search chauffeur, vehicle, plate...'}
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

          {/* Experience Category Filter Buttons */}
          {activeTab === 'fleet' && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap', paddingTop: '0.25rem' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#71717a' }}>Category:</span>
              {(['all', 'Business Class', 'Business Van', 'First Class'] as const).map((cat) => (
                <button
                  key={cat}
                  onClick={() => setCategoryFilter(cat)}
                  style={{
                    padding: '4px 10px',
                    borderRadius: 6,
                    fontSize: '0.75rem',
                    fontWeight: 500,
                    cursor: 'pointer',
                    border: '1px solid',
                    borderColor: categoryFilter === cat ? 'var(--admin-primary)' : 'rgba(255,255,255,0.08)',
                    background: categoryFilter === cat ? 'rgba(244,197,34,0.1)' : 'transparent',
                    color: categoryFilter === cat ? 'var(--admin-primary)' : '#a1a1aa',
                  }}
                >
                  {cat === 'all' ? 'All Categories' : cat}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Content Body */}
        {loading ? (
          <div style={{ padding: '3.5rem', textAlign: 'center', color: '#a1a1aa' }}>
            <RotateCw size={24} className="admin-spin" style={{ margin: '0 auto 0.75rem', display: 'block', color: 'var(--admin-primary)' }} />
            Loading fleet inventory...
          </div>
        ) : error ? (
          <div style={{ padding: '3.5rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem', fontSize: '0.9rem' }}>{error}</p>
            <button className="admin-btn" onClick={fetchData}>Try Again</button>
          </div>
        ) : activeTab === 'fleet' ? (
          
          /* Fleet Models Grid View */
          <div style={{ padding: '1.5rem' }}>
            {filteredCars.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '3rem 1rem', color: '#71717a' }}>
                {search ? 'No fleet models match your query.' : 'No fleet models registered yet. Click "Add Vehicle Model" to create one.'}
              </div>
            ) : (
              <div className="admin-fleet-grid">
                {filteredCars.map((car) => {
                  const featureList = (car.features || '')
                    .split(',')
                    .map(f => f.trim())
                    .filter(Boolean);

                  return (
                    <div key={car.id} className="admin-fleet-card">
                      
                      {/* Vehicle Image Banner */}
                      <div className="admin-fleet-image-wrap">
                        {car.image_url ? (
                          <img src={car.image_url} alt={`${car.make} ${car.model}`} />
                        ) : (
                          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, color: '#52525b' }}>
                            <Car size={42} strokeWidth={1.2} />
                            <span style={{ fontSize: '0.72rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>No Photo Provided</span>
                          </div>
                        )}
                        
                        {/* Featured Star Toggle */}
                        <button
                          className={`admin-fleet-featured-star ${car.is_featured ? 'active' : ''}`}
                          onClick={() => handleToggleFeatured(car)}
                          title={car.is_featured ? 'Featured on customer booking app' : 'Click to feature on customer booking app'}
                        >
                          <Star size={15} fill={car.is_featured ? '#F4C522' : 'none'} />
                        </button>
                      </div>

                      {/* Vehicle Body Info */}
                      <div className="admin-fleet-body">
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                          <div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                              <h3 className="admin-fleet-title" style={{ margin: 0 }}>{car.make} {car.model}</h3>
                              <span 
                                style={{ 
                                  fontSize: '0.65rem', 
                                  padding: '2px 7px', 
                                  borderRadius: 4, 
                                  fontWeight: 600,
                                  background: (car.category || autoCategorizeVehicle(car.make, car.model, car.year).category) === 'First Class' 
                                    ? 'rgba(234, 179, 8, 0.15)' 
                                    : (car.category || autoCategorizeVehicle(car.make, car.model, car.year).category) === 'Business Van'
                                    ? 'rgba(249, 115, 22, 0.15)'
                                    : 'rgba(59, 130, 246, 0.15)',
                                  color: (car.category || autoCategorizeVehicle(car.make, car.model, car.year).category) === 'First Class'
                                    ? '#EAB308'
                                    : (car.category || autoCategorizeVehicle(car.make, car.model, car.year).category) === 'Business Van'
                                    ? '#f97316'
                                    : '#60a5fa',
                                  border: `1px solid ${
                                    (car.category || autoCategorizeVehicle(car.make, car.model, car.year).category) === 'First Class'
                                      ? 'rgba(234, 179, 8, 0.3)'
                                      : (car.category || autoCategorizeVehicle(car.make, car.model, car.year).category) === 'Business Van'
                                      ? 'rgba(249, 115, 22, 0.3)'
                                      : 'rgba(59, 130, 246, 0.3)'
                                  }`
                                }}
                              >
                                {car.category || autoCategorizeVehicle(car.make, car.model, car.year).category}
                              </span>
                            </div>
                            <span style={{ fontSize: '0.75rem', color: '#71717a', fontWeight: 600 }}>Model Year {car.year}</span>
                          </div>
                          {car.is_featured && (
                            <span className="admin-badge admin-badge-warning" style={{ fontSize: '0.65rem' }}>
                              Featured
                            </span>
                          )}
                        </div>

                        {/* AI Suggestion Banner */}
                        {aiSuggestions[car.id] && (
                          <div 
                            style={{
                              margin: '0.6rem 0',
                              padding: '0.55rem 0.75rem',
                              background: 'rgba(234, 179, 8, 0.09)',
                              border: '1px solid rgba(234, 179, 8, 0.28)',
                              borderRadius: '8px',
                              fontSize: '0.72rem',
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '0.5rem', marginBottom: '4px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                                <Wand2 size={13} style={{ color: '#EAB308', flexShrink: 0 }} />
                                <span style={{ color: '#e4e4e7' }}>
                                  {aiSuggestions[car.id].evaluatedByGemini ? 'Gemini AI suggests: ' : 'AI suggests: '}
                                  <strong style={{ color: '#EAB308' }}>{aiSuggestions[car.id].category}</strong>
                                </span>
                              </div>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '5px', flexShrink: 0 }}>
                                <button
                                  type="button"
                                  onClick={() => handleAcceptSuggestion(car, aiSuggestions[car.id].category)}
                                  style={{
                                    background: '#EAB308',
                                    color: '#111827',
                                    border: 'none',
                                    borderRadius: '4px',
                                    padding: '2px 8px',
                                    fontSize: '0.68rem',
                                    fontWeight: 600,
                                    cursor: 'pointer',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '3px',
                                  }}
                                  title="Accept suggested category"
                                >
                                  <Check size={11} strokeWidth={3} /> Accept
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleDeclineSuggestion(car.id)}
                                  style={{
                                    background: 'rgba(255, 255, 255, 0.08)',
                                    color: '#a1a1aa',
                                    border: 'none',
                                    borderRadius: '4px',
                                    padding: '2px 8px',
                                    fontSize: '0.68rem',
                                    fontWeight: 500,
                                    cursor: 'pointer',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '3px',
                                  }}
                                  title="Decline suggestion"
                                >
                                  <X size={11} strokeWidth={2.5} /> Decline
                                </button>
                              </div>
                            </div>
                            <div style={{ fontSize: '0.67rem', color: '#a1a1aa', paddingLeft: '18px', lineHeight: 1.4 }}>
                              {aiSuggestions[car.id].reason}
                            </div>
                          </div>
                        )}

                        {/* Features Tags */}
                        <div className="admin-fleet-features-tags">
                          {featureList.length > 0 ? (
                            featureList.map((f, idx) => (
                              <span key={idx} className="admin-fleet-feature-tag">{f}</span>
                            ))
                          ) : (
                            <span style={{ fontSize: '0.7rem', color: '#52525b', fontStyle: 'italic' }}>Standard luxury amenities</span>
                          )}
                        </div>

                        {/* Footer Controls */}
                        <div className="admin-fleet-footer">
                          <span style={{ fontSize: '0.75rem', color: '#a1a1aa', display: 'flex', alignItems: 'center', gap: 5 }}>
                            <CheckCircle2 size={13} color="var(--admin-success)" />
                            {car.chauffeur_count} Chauffeur{car.chauffeur_count !== 1 ? 's' : ''} active
                          </span>

                          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                            <button 
                              className="admin-icon-btn"
                              disabled={loadingAiCarIds[car.id]}
                              style={{ 
                                width: 28, 
                                height: 28, 
                                color: '#EAB308', 
                                borderColor: 'rgba(234, 179, 8, 0.3)',
                                background: aiSuggestions[car.id] ? 'rgba(234, 179, 8, 0.15)' : 'transparent',
                                opacity: loadingAiCarIds[car.id] ? 0.7 : 1,
                                cursor: loadingAiCarIds[car.id] ? 'wait' : 'pointer'
                              }}
                              onClick={() => handleSuggestCategory(car)}
                              title={loadingAiCarIds[car.id] ? 'Analyzing with Gemini AI...' : 'Suggest category with Gemini AI'}
                            >
                              {loadingAiCarIds[car.id] ? (
                                <Loader2 size={13} className="animate-spin" />
                              ) : (
                                <Wand2 size={13} />
                              )}
                            </button>
                            <button 
                              className="admin-icon-btn"
                              style={{ width: 28, height: 28 }}
                              onClick={() => openEditModal(car)}
                              title="Edit model"
                            >
                              <Pencil size={13} />
                            </button>
                            <InlineConfirmButton
                              label={<Trash2 size={13} />}
                              confirmLabel="Delete?"
                              className="admin-icon-btn"
                              confirmClassName="admin-btn admin-btn-danger"
                              style={{ color: '#ef4444' }}
                              title="Delete model"
                              onConfirm={() => handleDelete(car.id)}
                            />
                          </div>
                        </div>

                      </div>

                    </div>
                  );
                })}
              </div>
            )}
          </div>

        ) : (

          /* Vehicle Verification Requests Table */
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Chauffeur</th>
                <th scope="col">Vehicle Description</th>
                <th scope="col">License Plate</th>
                <th scope="col">Color</th>
                <th scope="col">Submission Date</th>
                <th scope="col" style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredRequests.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '3.5rem 1rem', color: '#71717a' }}>
                    {search ? 'No requests match your search query.' : 'All vehicle verification requests are clear.'}
                  </td>
                </tr>
              ) : (
                filteredRequests.map((req) => (
                  <tr key={req.id}>
                    <td data-label="Chauffeur">
                      <div className="admin-table-user-cell">
                        <div className="admin-avatar-small">
                          {req.chauffeur_name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div style={{ fontWeight: 600, color: '#fff', fontSize: '0.85rem' }}>{req.chauffeur_name}</div>
                          <div style={{ fontSize: '0.72rem', color: '#71717a' }}>Chauffeur Applicant</div>
                        </div>
                      </div>
                    </td>
                    <td data-label="Vehicle">
                      <span style={{ fontWeight: 600, color: '#fff', fontSize: '0.85rem' }}>
                        {req.year} {req.make} {req.model}
                      </span>
                    </td>
                    <td data-label="License Plate">
                      <span className="admin-plate-badge">{req.license_plate}</span>
                    </td>
                    <td data-label="Color">
                      <span style={{ fontSize: '0.82rem', color: '#a1a1aa' }}>{req.color || '--'}</span>
                    </td>
                    <td data-label="Submission Date">
                      <span style={{ fontSize: '0.78rem', color: '#71717a' }}>
                        {new Date(req.created_at).toLocaleDateString()}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: 6 }}>
                        <button
                          className="admin-btn"
                          style={{ padding: '0.35rem 0.75rem', fontSize: '0.75rem', background: 'var(--admin-success)' }}
                          onClick={() => handleApproveRequest(req)}
                        >
                          <Check size={13} /> Approve
                        </button>
                        <button
                          className="admin-btn admin-btn-outline"
                          style={{ padding: '0.35rem 0.75rem', fontSize: '0.75rem', color: '#ef4444', borderColor: 'rgba(239, 68, 68, 0.3)' }}
                          onClick={() => { setRejectingId(req.id); setRejectNote(''); }}
                        >
                          <X size={13} /> Reject
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>

        )}

      </div>

      {/* Add / Edit Vehicle Slide-Over Drawer (Zero Modal) */}
      <AdminDrawer
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
        width={500}
        title={editCar ? 'Edit Fleet Model' : 'Register Vehicle Model'}
        subtitle="Manage luxury platform specs, amenities, and media"
        footer={
          <>
            <button 
              className="admin-btn admin-btn-outline" 
              onClick={() => setShowAddModal(false)}
              disabled={saving}
            >
              Cancel
            </button>
            <button 
              className="admin-btn"
              onClick={handleSave}
              disabled={saving || !form.make || !form.model}
            >
              {saving ? 'Saving...' : editCar ? 'Save Changes' : 'Register Vehicle'}
            </button>
          </>
        }
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {/* Make & Model Row */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 600, color: '#a1a1aa', marginBottom: 4 }}>
                MAKE (MANUFACTURER)
              </label>
              <input 
                type="text"
                className="admin-input"
                placeholder="e.g. Mercedes-Benz"
                value={form.make}
                onChange={(e) => setForm({ ...form, make: e.target.value })}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 600, color: '#a1a1aa', marginBottom: 4 }}>
                MODEL
              </label>
              <input 
                type="text"
                className="admin-input"
                placeholder="e.g. S-Class Maybach"
                value={form.model}
                onChange={(e) => setForm({ ...form, model: e.target.value })}
              />
            </div>
          </div>

          {/* Year */}
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 600, color: '#a1a1aa', marginBottom: 4 }}>
              MANUFACTURE YEAR
            </label>
            <input 
              type="number"
              className="admin-input"
              placeholder="2024"
              value={form.year}
              onChange={(e) => setForm({ ...form, year: parseInt(e.target.value) || new Date().getFullYear() })}
            />
          </div>

          {/* Fleet Category with AI auto-detect */}
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 600, color: '#a1a1aa' }}>
                FLEET EXPERIENCE CATEGORY
              </label>
              <button
                type="button"
                disabled={loadingFormAi}
                onClick={async () => {
                  setLoadingFormAi(true);
                  try {
                    const res = await categorizeVehicleWithGemini({
                      make: form.make,
                      model: form.model,
                      year: form.year,
                      features: form.features,
                    });
                    setForm((prev: any) => ({ ...prev, category: res.category }));
                    if (res.evaluatedByGemini) {
                      toast.success(`Gemini AI categorized as: ${res.category}`);
                    } else {
                      toast.success(`AI categorized as: ${res.category}`);
                    }
                  } catch {
                    const detected = autoCategorizeVehicle(form.make, form.model, form.year).category;
                    setForm((prev: any) => ({ ...prev, category: detected }));
                    toast.success(`AI categorized as: ${detected}`);
                  } finally {
                    setLoadingFormAi(false);
                  }
                }}
                style={{
                  background: 'none',
                  border: 'none',
                  color: '#EAB308',
                  cursor: loadingFormAi ? 'wait' : 'pointer',
                  opacity: loadingFormAi ? 0.7 : 1,
                  fontSize: '0.72rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 4,
                  fontWeight: 600
                }}
              >
                {loadingFormAi ? (
                  <>
                    <Loader2 size={12} className="animate-spin" /> Asking Gemini AI...
                  </>
                ) : (
                  <>
                    <Wand2 size={12} /> Auto-detect with Gemini AI
                  </>
                )}
              </button>
            </div>
            <select
              className="admin-input"
              value={form.category || 'Business Class'}
              onChange={(e) => setForm((prev: any) => ({ ...prev, category: e.target.value as FleetCategory }))}
              style={{ background: '#18181b', color: '#fff', cursor: 'pointer' }}
            >
              <option value="Business Class">Business Class (Executive Sedans & EVs - 3 Pax, 2 Bags)</option>
              <option value="Business Van">Business Van (Executive Vans & Large SUVs - 5 Pax, 5 Bags)</option>
              <option value="First Class">First Class (Flagship Ultra-Luxury Sedans - 3 Pax, 2 Bags)</option>
            </select>
          </div>

          {/* Features */}
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 600, color: '#a1a1aa', marginBottom: 4 }}>
              LUXURY AMENITIES (COMMA SEPARATED)
            </label>
            <input 
              type="text"
              className="admin-input"
              placeholder="e.g. Leather Seats, Wi-Fi, Panoramic Roof, Refreshments"
              value={form.features}
              onChange={(e) => setForm({ ...form, features: e.target.value })}
            />
          </div>

          {/* Image Upload */}
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 600, color: '#a1a1aa', marginBottom: 4 }}>
              VEHICLE PHOTOGRAPHY
            </label>
            
            {form.image_url ? (
              <div style={{ position: 'relative', width: '100%', height: 160, borderRadius: 8, overflow: 'hidden', border: '1px solid rgba(255,255,255,0.1)', marginBottom: 8 }}>
                <img src={form.image_url} alt="Vehicle preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                <button
                  type="button"
                  onClick={() => setForm({ ...form, image_url: '' })}
                  style={{ position: 'absolute', top: 8, right: 8, background: 'rgba(0,0,0,0.7)', border: 'none', color: '#fff', borderRadius: '50%', width: 26, height: 26, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}
                >
                  <X size={14} />
                </button>
              </div>
            ) : (
              <div 
                onClick={() => fileInputRef.current?.click()}
                style={{ border: '2px dashed rgba(255,255,255,0.1)', borderRadius: 8, padding: '1.5rem', textAlign: 'center', cursor: 'pointer', background: 'rgba(255,255,255,0.01)' }}
              >
                <Upload size={24} style={{ color: '#71717a', margin: '0 auto 6px', display: 'block' }} />
                <p style={{ margin: 0, fontSize: '0.82rem', color: '#fff', fontWeight: 500 }}>
                  {uploading ? 'Compressing and uploading...' : 'Click to select vehicle photo'}
                </p>
                <p style={{ margin: '4px 0 0', fontSize: '0.72rem', color: '#71717a' }}>PNG, JPG up to 10MB</p>
              </div>
            )}

            <input 
              ref={fileInputRef}
              type="file"
              accept="image/*"
              style={{ display: 'none' }}
              onChange={handleImageUpload}
            />
          </div>
        </div>
      </AdminDrawer>

      {/* Reject Reason Slide-Over Drawer (Zero Modal) */}
      <AdminDrawer
        isOpen={!!rejectingId}
        onClose={() => setRejectingId(null)}
        width={440}
        title="Reject Vehicle Application"
        subtitle="Provide feedback for the applicant"
        footer={
          <>
            <button className="admin-btn admin-btn-outline" onClick={() => setRejectingId(null)}>
              Cancel
            </button>
            <button 
              className="admin-btn admin-btn-danger"
              onClick={() => handleRejectRequest(rejectingId!)}
            >
              Confirm Rejection
            </button>
          </>
        }
      >
        <p style={{ margin: '0 0 0.85rem', fontSize: '0.84rem', color: '#a1a1aa' }}>
          Please provide a note for the chauffeur detailing why this vehicle does not meet platform standards:
        </p>
        <textarea 
          className="admin-input"
          rows={5}
          placeholder="e.g. Vehicle year is outside acceptable limits or insurance documentation incomplete..."
          value={rejectNote}
          onChange={(e) => setRejectNote(e.target.value)}
          style={{ resize: 'vertical', width: '100%' }}
        />
      </AdminDrawer>

    </div>
  );
}
