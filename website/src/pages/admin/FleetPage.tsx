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
  Loader2,
  Sparkles,
  AlertCircle,
  Tag
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

const emptyCar = { make: '', model: '', year: new Date().getFullYear(), image_url: '', features: '', category: 'None' as FleetCategory };

function getCategoryBadgeStyle(cat?: FleetCategory | string) {
  switch (cat) {
    case 'Buses':
      return {
        background: 'rgba(168, 85, 247, 0.12)',
        color: '#c084fc',
        border: '1px solid rgba(168, 85, 247, 0.35)',
      };
    case 'Vans':
    case 'Business Van':
      return {
        background: 'rgba(249, 115, 22, 0.12)',
        color: '#f97316',
        border: '1px solid rgba(249, 115, 22, 0.35)',
      };
    case 'SUVs':
      return {
        background: 'rgba(234, 179, 8, 0.12)',
        color: '#EAB308',
        border: '1px solid rgba(234, 179, 8, 0.35)',
      };
    case 'Sedans':
    case 'Business Class':
    case 'First Class':
      return {
        background: 'rgba(59, 130, 246, 0.12)',
        color: '#60a5fa',
        border: '1px solid rgba(59, 130, 246, 0.35)',
      };
    default:
      return {};
  }
}

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

      const localCatMap: Record<string, FleetCategory> = (() => {
        try {
          return JSON.parse(localStorage.getItem('kenick_fleet_car_categories') || '{}');
        } catch {
          return {};
        }
      })();

      setFleetCars(
        (cars || []).map((c) => ({
          ...c,
          category: localCatMap[c.id] || ((c as any).category as FleetCategory) || 'None',
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
      const currentCat = c.category || 'None';
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
    setForm({ make: car.make, model: car.model, year: car.year, image_url: car.image_url || '', features: car.features || '', category: car.category || 'None' });
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
        toast.info(`Kenick AI recommends "${res.category}"`);
      } else {
        toast.info(`Kenick AI recommends "${res.category}"`);
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

  const handleSetAllToNone = () => {
    setFleetCars((prev) => prev.map((c) => ({ ...c, category: 'None' })));
    try {
      localStorage.removeItem('kenick_fleet_car_categories');
    } catch {}
    toast.info('All vehicles set to "None" category');
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

      try {
        const currentLocal = JSON.parse(localStorage.getItem('kenick_fleet_car_categories') || '{}');
        currentLocal[car.id] = suggestedCat;
        localStorage.setItem('kenick_fleet_car_categories', JSON.stringify(currentLocal));
      } catch {}

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
      const cat = form.category || 'None';
      const payloadWithCat = { ...basePayload, category: cat };

      if (editCar) {
        try {
          const currentLocal = JSON.parse(localStorage.getItem('kenick_fleet_car_categories') || '{}');
          currentLocal[editCar.id] = cat;
          localStorage.setItem('kenick_fleet_car_categories', JSON.stringify(currentLocal));
        } catch {}
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
          .insert(payloadWithCat)
          .select()
          .single();
        if (res.error) {
          res = await supabase.from('fleet_cars').insert(basePayload).select().single();
          if (res.error) throw res.error;
        }
        if (res.data?.id) {
          try {
            const currentLocal = JSON.parse(localStorage.getItem('kenick_fleet_car_categories') || '{}');
            currentLocal[res.data.id] = cat;
            localStorage.setItem('kenick_fleet_car_categories', JSON.stringify(currentLocal));
          } catch {}
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
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', flexWrap: 'wrap', paddingTop: '0.35rem' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 600, color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                Category:
              </span>
              {(['all', 'Sedans', 'SUVs', 'Vans', 'Buses', 'None'] as const).map((cat) => {
                const isSelected = categoryFilter === cat;
                const count = cat === 'all'
                  ? fleetCars.length
                  : cat === 'None'
                  ? fleetCars.filter(c => !c.category || c.category === 'None').length
                  : fleetCars.filter(c => c.category === cat).length;

                return (
                  <button
                    key={cat}
                    onClick={() => setCategoryFilter(cat)}
                    style={{
                      padding: '5px 12px',
                      borderRadius: 9999,
                      fontSize: '0.75rem',
                      fontWeight: isSelected ? 600 : 500,
                      cursor: 'pointer',
                      border: '1px solid',
                      borderColor: isSelected ? '#EAB308' : 'rgba(255, 255, 255, 0.08)',
                      background: isSelected ? 'rgba(234, 179, 8, 0.12)' : 'rgba(255, 255, 255, 0.02)',
                      color: isSelected ? '#EAB308' : '#a1a1aa',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                      transition: 'all 0.18s ease'
                    }}
                  >
                    <span>{cat === 'all' ? 'All Models' : cat === 'None' ? 'Unassigned' : cat}</span>
                    <span
                      style={{
                        fontSize: '0.65rem',
                        padding: '1px 6px',
                        borderRadius: 9999,
                        background: isSelected ? 'rgba(234, 179, 8, 0.25)' : 'rgba(255, 255, 255, 0.06)',
                        color: isSelected ? '#EAB308' : '#71717a',
                      }}
                    >
                      {count}
                    </span>
                  </button>
                );
              })}

              <button
                type="button"
                onClick={handleSetAllToNone}
                style={{
                  marginLeft: 'auto',
                  padding: '5px 12px',
                  borderRadius: 9999,
                  fontSize: '0.72rem',
                  fontWeight: 500,
                  cursor: 'pointer',
                  border: '1px solid rgba(255, 255, 255, 0.08)',
                  background: 'rgba(255, 255, 255, 0.02)',
                  color: '#71717a',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 5,
                  transition: 'all 0.18s ease'
                }}
                title="Reset all fleet vehicle categories to None"
              >
                <RotateCw size={11} /> Reset All to None
              </button>
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
                          <Star size={15} fill={car.is_featured ? '#EAB308' : 'none'} color={car.is_featured ? '#EAB308' : '#71717A'} />
                        </button>
                      </div>

                      {/* Vehicle Body Info */}
                      <div className="admin-fleet-body">
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 10 }}>
                          <div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4, flexWrap: 'wrap' }}>
                              <h3 className="admin-fleet-title" style={{ margin: 0 }}>{car.make} {car.model}</h3>
                              {car.category && car.category !== 'None' && (
                                <span 
                                  style={{ 
                                    fontSize: '0.67rem', 
                                    padding: '2px 9px', 
                                    borderRadius: 9999, 
                                    fontWeight: 600,
                                    letterSpacing: '0.02em',
                                    display: 'inline-flex',
                                    alignItems: 'center',
                                    ...getCategoryBadgeStyle(car.category)
                                  }}
                                >
                                  {car.category}
                                </span>
                              )}
                            </div>
                            <span style={{ fontSize: '0.74rem', color: '#71717a', fontWeight: 500, letterSpacing: '0.01em' }}>Model Year {car.year}</span>
                          </div>
                          {car.is_featured && (
                            <span 
                              style={{ 
                                fontSize: '0.65rem', 
                                padding: '3px 8px', 
                                borderRadius: 9999, 
                                fontWeight: 600,
                                background: 'rgba(234, 179, 8, 0.12)',
                                border: '1px solid rgba(234, 179, 8, 0.35)',
                                color: '#EAB308',
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: 4,
                                flexShrink: 0
                              }}
                            >
                              <Star size={10} fill="#EAB308" /> Featured
                            </span>
                          )}
                        </div>

                        {/* AI Suggestion Banner */}
                        {aiSuggestions[car.id] && (
                          <div 
                            style={{
                              margin: '0.75rem 0 0.5rem',
                              padding: '0.7rem 0.85rem',
                              background: 'linear-gradient(135deg, rgba(234, 179, 8, 0.08) 0%, rgba(20, 20, 22, 0.95) 100%)',
                              border: '1px solid rgba(234, 179, 8, 0.3)',
                              borderRadius: '14px',
                              fontSize: '0.72rem',
                              boxShadow: '0 4px 14px rgba(0, 0, 0, 0.35)',
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '0.5rem', marginBottom: '5px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                <div style={{ width: 20, height: 20, borderRadius: '50%', background: 'rgba(234, 179, 8, 0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                  <Wand2 size={11} style={{ color: '#EAB308' }} />
                                </div>
                                <span style={{ color: '#e4e4e7', fontWeight: 500 }}>
                                  Kenick AI suggests: <strong style={{ color: '#EAB308', fontWeight: 600 }}>{aiSuggestions[car.id].category}</strong>
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
                                    borderRadius: 9999,
                                    padding: '3px 10px',
                                    fontSize: '0.7rem',
                                    fontWeight: 600,
                                    cursor: 'pointer',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '3px',
                                    boxShadow: '0 2px 6px rgba(234, 179, 8, 0.25)'
                                  }}
                                  title="Accept suggested category"
                                >
                                  <Check size={11} strokeWidth={3} /> Accept
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleDeclineSuggestion(car.id)}
                                  style={{
                                    background: 'rgba(255, 255, 255, 0.06)',
                                    color: '#a1a1aa',
                                    border: '1px solid rgba(255, 255, 255, 0.1)',
                                    borderRadius: 9999,
                                    padding: '3px 9px',
                                    fontSize: '0.7rem',
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
                            <div style={{ fontSize: '0.68rem', color: '#a1a1aa', paddingLeft: '26px', lineHeight: 1.45 }}>
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
                          <span style={{ fontSize: '0.75rem', color: '#a1a1aa', display: 'flex', alignItems: 'center', gap: 6 }}>
                            <div style={{ width: 7, height: 7, borderRadius: '50%', background: car.chauffeur_count > 0 ? '#10b981' : '#52525b' }} />
                            <span>{car.chauffeur_count} Chauffeur{car.chauffeur_count !== 1 ? 's' : ''} assigned</span>
                          </span>

                          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                            <button 
                              className="admin-icon-btn"
                              disabled={loadingAiCarIds[car.id]}
                              style={{ 
                                width: 30, 
                                height: 30, 
                                borderRadius: 8,
                                color: '#EAB308', 
                                borderColor: aiSuggestions[car.id] ? '#EAB308' : 'rgba(234, 179, 8, 0.3)',
                                background: aiSuggestions[car.id] ? 'rgba(234, 179, 8, 0.15)' : 'rgba(234, 179, 8, 0.04)',
                                opacity: loadingAiCarIds[car.id] ? 0.7 : 1,
                                cursor: loadingAiCarIds[car.id] ? 'wait' : 'pointer',
                                transition: 'all 0.18s ease'
                              }}
                              onClick={() => handleSuggestCategory(car)}
                              title={loadingAiCarIds[car.id] ? 'Analyzing with Kenick AI...' : 'Suggest category with Kenick AI'}
                            >
                              {loadingAiCarIds[car.id] ? (
                                <Loader2 size={13} className="animate-spin" />
                              ) : (
                                <Wand2 size={13} />
                              )}
                            </button>
                            <button 
                              className="admin-icon-btn"
                              style={{ width: 30, height: 30, borderRadius: 8 }}
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
                              style={{ width: 30, height: 30, borderRadius: 8, color: '#ef4444' }}
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
        width={560}
        title={editCar ? 'Edit Fleet Model' : 'Register Vehicle Model'}
        subtitle="Platform luxury specs, experience tier classification & vehicle photography"
        footer={
          <>
            <button 
              type="button"
              className="drawer-btn-outline" 
              onClick={() => setShowAddModal(false)}
              disabled={saving}
            >
              Cancel
            </button>
            <button 
              type="button"
              className="drawer-btn-primary"
              onClick={handleSave}
              disabled={saving || !form.make || !form.model}
            >
              {saving ? (
                <>
                  <Loader2 size={16} className="animate-spin" />
                  <span>Saving...</span>
                </>
              ) : (
                <>
                  <Check size={16} />
                  <span>{editCar ? 'Save Changes' : 'Register Vehicle'}</span>
                </>
              )}
            </button>
          </>
        }
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {/* Section 1: Vehicle Specifications */}
          <div className="drawer-section-card">
            <div className="drawer-section-header">
              <span className="drawer-section-title">Vehicle Specifications</span>
              <span style={{ fontSize: '0.7rem', color: '#71717A', fontWeight: 500 }}>Make & Model Identity</span>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.85rem' }}>
              <div>
                <label className="drawer-label">
                  Manufacturer (Make)
                </label>
                <input 
                  type="text"
                  className="drawer-input"
                  placeholder="e.g. Mercedes-Benz"
                  value={form.make}
                  onChange={(e) => setForm({ ...form, make: e.target.value })}
                />
              </div>

              <div>
                <label className="drawer-label">
                  Vehicle Model
                </label>
                <input 
                  type="text"
                  className="drawer-input"
                  placeholder="e.g. S-Class Maybach"
                  value={form.model}
                  onChange={(e) => setForm({ ...form, model: e.target.value })}
                />
              </div>
            </div>

            <div>
              <label className="drawer-label">
                Manufacture Year
              </label>
              <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                <input 
                  type="number"
                  className="drawer-input"
                  placeholder="2024"
                  value={form.year}
                  onChange={(e) => setForm({ ...form, year: parseInt(e.target.value) || new Date().getFullYear() })}
                  style={{ width: 140 }}
                />
                <div style={{ display: 'flex', gap: '0.35rem', flexWrap: 'wrap' }}>
                  {[new Date().getFullYear(), new Date().getFullYear() - 1, new Date().getFullYear() - 2].map(y => (
                    <button
                      key={y}
                      type="button"
                      onClick={() => setForm({ ...form, year: y })}
                      style={{
                        background: form.year === y ? 'rgba(234, 179, 8, 0.15)' : 'rgba(255, 255, 255, 0.04)',
                        border: `1px solid ${form.year === y ? '#EAB308' : '#27272A'}`,
                        color: form.year === y ? '#EAB308' : '#A1A1AA',
                        borderRadius: 6,
                        padding: '4px 10px',
                        fontSize: '0.72rem',
                        fontWeight: 600,
                        cursor: 'pointer',
                        transition: 'all 0.15s ease'
                      }}
                    >
                      {y}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Section 2: Fleet Category with Kenick AI */}
          <div className="drawer-section-card">
            <div className="drawer-section-header">
              <span className="drawer-section-title">Fleet Experience Tier</span>
              <button
                type="button"
                className="drawer-ai-pill"
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
                    toast.success(`Kenick AI categorized as: ${res.category}`);
                  } catch {
                    const detected = autoCategorizeVehicle(form.make, form.model, form.year).category;
                    setForm((prev: any) => ({ ...prev, category: detected }));
                    toast.success(`Kenick AI categorized as: ${detected}`);
                  } finally {
                    setLoadingFormAi(false);
                  }
                }}
              >
                {loadingFormAi ? (
                  <>
                    <Loader2 size={13} className="animate-spin" /> Asking Kenick AI...
                  </>
                ) : (
                  <>
                    <Wand2 size={13} /> Auto-detect with Kenick AI
                  </>
                )}
              </button>
            </div>

            <div>
              <label className="drawer-label">
                Assigned Platform Category
              </label>
              <select
                className="drawer-input"
                value={form.category || 'None'}
                onChange={(e) => setForm((prev: any) => ({ ...prev, category: e.target.value as FleetCategory }))}
                style={{ cursor: 'pointer', background: '#121316', color: '#fff' }}
              >
                <option value="None">None (Unassigned — No badge shown to clients)</option>
                <option value="Sedans">Sedans (Lowest Pricing • Mercedes S/E-Class, BMW 7/5 Series, Audi A8/A6)</option>
                <option value="SUVs">SUVs (Prestige SUVs • Cadillac Escalade, GMC Yukon, Lincoln Navigator, Range Rover)</option>
                <option value="Vans">Vans (Executive MPVs & Sprinters • Mercedes V-Class, Metris)</option>
                <option value="Buses">Buses (Highest Pricing • VIP Minibuses & Coaches 16+ Pax)</option>


              </select>
            </div>

            {/* Contextual Tier Guide Box */}
            <div style={{
              background: 'rgba(255, 255, 255, 0.02)',
              border: '1px solid #27272A',
              borderRadius: 10,
              padding: '0.75rem 0.9rem',
              display: 'flex',
              alignItems: 'flex-start',
              gap: '0.65rem'
            }}>
              <Sparkles size={16} style={{ color: form.category === 'First Class' ? '#EAB308' : form.category === 'Business Class' ? '#60A5FA' : form.category === 'Business Van' ? '#A78BFA' : '#71717A', marginTop: 2, flexShrink: 0 }} />
              <div style={{ fontSize: '0.75rem', lineHeight: 1.45 }}>
                <span style={{ fontWeight: 600, color: '#fff' }}>
                  {form.category === 'First Class' ? 'First Class Standard:' :
                   form.category === 'Business Class' ? 'Business Class Standard:' :
                   form.category === 'Business Van' ? 'Business Van Standard:' :
                   'Unassigned Category:'}
                </span>{' '}
                <span style={{ color: '#A1A1AA' }}>
                  {form.category === 'First Class' ? 'Mercedes-Benz S-Class, Mercedes-Maybach, BMW 7 Series, Audi A8, Lexus LS, Porsche Panamera.' :
                   form.category === 'Business Class' ? 'Mercedes-Benz E-Class, BMW 5 Series, Audi A6, Lexus ES, Genesis G80.' :
                   form.category === 'Business Van' ? 'Mercedes-Benz V-Class, Volkswagen Multivan, Toyota Alphard, Lexus LM.' :
                   'Vehicle will not show a tier badge on customer dispatch and search results.'}
                </span>
              </div>
            </div>
          </div>

          {/* Section 3: Luxury Amenities & Features */}
          <div className="drawer-section-card">
            <div className="drawer-section-header">
              <span className="drawer-section-title">Luxury Amenities</span>
              <span style={{ fontSize: '0.7rem', color: '#71717A', fontWeight: 500 }}>In-Cabin Comforts</span>
            </div>

            <div>
              <label className="drawer-label">
                Amenities List (Comma-Separated)
              </label>
              <input 
                type="text"
                className="drawer-input"
                placeholder="e.g. Leather Seats, Wi-Fi 5G, Panoramic Roof, Chilled Refreshments"
                value={form.features}
                onChange={(e) => setForm({ ...form, features: e.target.value })}
              />
            </div>

            {/* Quick-add recommendation chips */}
            <div>
              <div style={{ fontSize: '0.7rem', color: '#71717A', fontWeight: 600, letterSpacing: '0.04em', textTransform: 'uppercase', marginBottom: 6 }}>
                Quick Suggestions:
              </div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.4rem' }}>
                {[
                  'Leather Seats',
                  'Wi-Fi 5G',
                  'Panoramic Roof',
                  'Chilled Refreshments',
                  'Massage Seats',
                  'Privacy Glass',
                  'Rear Climate Control',
                  'Burmester Sound'
                ].map(amenity => {
                  const existingList = form.features.split(',').map((s: string) => s.trim().toLowerCase());
                  const isSelected = existingList.includes(amenity.toLowerCase());
                  return (
                    <button
                      key={amenity}
                      type="button"
                      onClick={() => {
                        const items = form.features ? form.features.split(',').map((s: string) => s.trim()).filter(Boolean) : [];
                        const idx = items.findIndex((i: string) => i.toLowerCase() === amenity.toLowerCase());
                        if (idx >= 0) {
                          items.splice(idx, 1);
                        } else {
                          items.push(amenity);
                        }
                        setForm({ ...form, features: items.join(', ') });
                      }}
                      style={{
                        background: isSelected ? 'rgba(234, 179, 8, 0.15)' : 'rgba(255, 255, 255, 0.03)',
                        border: `1px solid ${isSelected ? '#EAB308' : '#27272A'}`,
                        color: isSelected ? '#EAB308' : '#A1A1AA',
                        borderRadius: 9999,
                        padding: '3px 9px',
                        fontSize: '0.7rem',
                        fontWeight: 500,
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4,
                        transition: 'all 0.15s ease'
                      }}
                    >
                      {isSelected ? <Check size={11} /> : <Plus size={11} />}
                      {amenity}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Live parsed badges */}
            {form.features && (
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.35rem', paddingTop: '0.35rem', borderTop: '1px solid #27272A' }}>
                {form.features.split(',').map((s: string) => s.trim()).filter(Boolean).map((tag: string, i: number) => (
                  <span
                    key={i}
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 4,
                      background: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid #27272A',
                      color: '#E4E4E7',
                      fontSize: '0.7rem',
                      fontWeight: 500,
                      padding: '2px 8px',
                      borderRadius: 6
                    }}
                  >
                    <Tag size={10} style={{ color: '#EAB308' }} />
                    {tag}
                    <X
                      size={11}
                      style={{ cursor: 'pointer', marginLeft: 2, color: '#71717A' }}
                      onClick={() => {
                        const items = form.features.split(',').map((s: string) => s.trim()).filter(Boolean);
                        items.splice(i, 1);
                        setForm({ ...form, features: items.join(', ') });
                      }}
                    />
                  </span>
                ))}
              </div>
            )}
          </div>

          {/* Section 4: Vehicle Photography */}
          <div className="drawer-section-card">
            <div className="drawer-section-header">
              <span className="drawer-section-title">Vehicle Photography</span>
              <span style={{ fontSize: '0.7rem', color: '#71717A', fontWeight: 500 }}>Editorial Asset</span>
            </div>
            
            {form.image_url ? (
              <div style={{ position: 'relative', width: '100%', height: 180, borderRadius: 12, overflow: 'hidden', border: '1px solid rgba(234, 179, 8, 0.3)', background: '#0a0a0c' }}>
                <img src={form.image_url} alt="Vehicle preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                <div style={{
                  position: 'absolute',
                  inset: 0,
                  background: 'linear-gradient(180deg, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.7) 100%)',
                  pointerEvents: 'none'
                }} />
                
                <div style={{ position: 'absolute', bottom: 10, left: 12, color: '#fff', fontSize: '0.75rem', fontWeight: 600 }}>
                  {form.make} {form.model} ({form.year})
                </div>

                <div style={{ position: 'absolute', top: 10, right: 10, display: 'flex', gap: 6 }}>
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    style={{
                      background: 'rgba(20, 20, 22, 0.85)',
                      border: '1px solid #27272A',
                      color: '#EAB308',
                      borderRadius: '50%',
                      width: 32,
                      height: 32,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      backdropFilter: 'blur(8px)'
                    }}
                    title="Replace Photo"
                  >
                    <Upload size={14} />
                  </button>
                  <button
                    type="button"
                    onClick={() => setForm({ ...form, image_url: '' })}
                    style={{
                      background: 'rgba(20, 20, 22, 0.85)',
                      border: '1px solid #27272A',
                      color: '#EF4444',
                      borderRadius: '50%',
                      width: 32,
                      height: 32,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      backdropFilter: 'blur(8px)'
                    }}
                    title="Remove Photo"
                  >
                    <X size={14} />
                  </button>
                </div>
              </div>
            ) : (
              <div 
                className="drawer-upload-zone"
                onClick={() => fileInputRef.current?.click()}
              >
                <div style={{
                  width: 44,
                  height: 44,
                  borderRadius: '50%',
                  background: 'rgba(234, 179, 8, 0.1)',
                  color: '#EAB308',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  margin: '0 auto 10px'
                }}>
                  {uploading ? <Loader2 size={22} className="animate-spin" /> : <Upload size={20} />}
                </div>
                <p style={{ margin: 0, fontSize: '0.84rem', color: '#FFFFFF', fontWeight: 600, fontFamily: 'Poppins, sans-serif' }}>
                  {uploading ? 'Compressing and uploading image...' : 'Select high-resolution photo'}
                </p>
                <p style={{ margin: '5px 0 0', fontSize: '0.72rem', color: '#A1A1AA', lineHeight: 1.4 }}>
                  PNG, JPG or WebP up to 10MB • Recommended 16:9 ratio
                </p>
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
        width={480}
        title="Reject Vehicle Application"
        subtitle="Provide structured compliance feedback for the chauffeur"
        footer={
          <>
            <button 
              type="button" 
              className="drawer-btn-outline" 
              onClick={() => setRejectingId(null)}
            >
              Cancel
            </button>
            <button 
              type="button"
              className="drawer-btn-danger"
              onClick={() => handleRejectRequest(rejectingId!)}
            >
              Confirm Rejection
            </button>
          </>
        }
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <div style={{
            background: 'rgba(239, 68, 68, 0.06)',
            border: '1px solid rgba(239, 68, 68, 0.25)',
            borderRadius: 12,
            padding: '0.85rem 1rem',
            display: 'flex',
            alignItems: 'flex-start',
            gap: '0.75rem'
          }}>
            <AlertCircle size={18} style={{ color: '#EF4444', flexShrink: 0, marginTop: 2 }} />
            <div style={{ fontSize: '0.78rem', color: '#FCA5A5', lineHeight: 1.45 }}>
              Rejecting this vehicle application will notify the chauffeur. Please specify the compliance deficiency clearly:
            </div>
          </div>

          <div>
            <div style={{ fontSize: '0.7rem', color: '#A1A1AA', fontWeight: 600, letterSpacing: '0.04em', textTransform: 'uppercase', marginBottom: 6 }}>
              Quick Compliance Feedback:
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              {[
                'Vehicle age exceeds platform limit for luxury registration.',
                'Missing or unverified commercial livery insurance document.',
                'Vehicle exterior or interior does not meet Kenick VIP quality standards.',
                'Mandatory safety inspection certification is missing or expired.'
              ].map((reason, idx) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => setRejectNote(reason)}
                  style={{
                    textAlign: 'left',
                    background: rejectNote === reason ? 'rgba(234, 179, 8, 0.12)' : 'rgba(255, 255, 255, 0.03)',
                    border: `1px solid ${rejectNote === reason ? '#EAB308' : '#27272A'}`,
                    color: rejectNote === reason ? '#EAB308' : '#D4D4D8',
                    borderRadius: 8,
                    padding: '6px 10px',
                    fontSize: '0.72rem',
                    cursor: 'pointer',
                    transition: 'all 0.15s ease'
                  }}
                >
                  • {reason}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="drawer-label">
              Detailed Chauffeur Feedback Note
            </label>
            <textarea 
              className="drawer-input"
              rows={5}
              placeholder="Detail reasons why this vehicle does not meet Kenick standards or steps required to re-apply..."
              value={rejectNote}
              onChange={(e) => setRejectNote(e.target.value)}
              style={{ resize: 'vertical', width: '100%', minHeight: 110 }}
            />
          </div>
        </div>
      </AdminDrawer>

    </div>
  );
}
