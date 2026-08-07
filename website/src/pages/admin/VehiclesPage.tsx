import { useEffect, useState, useMemo } from 'react';
import { Search, Download } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface VehicleRow {
  id: string;
  make: string;
  model: string;
  year: number;
  color: string;
  license_plate: string;
  is_active: boolean;
  driver_name: string | null;
  driver_id: string | null;
}

export default function VehiclesPage() {
  const [vehicles, setVehicles] = useState<VehicleRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchVehicles();
  }, []);

  const fetchVehicles = async () => {
    try {
      const { data: vehiclesData, error: vehicleError } = await supabase
        .from('vehicles')
        .select('id, driver_id, make, model, year, color, license_plate, is_active')
        .order('created_at', { ascending: false });

      if (vehicleError) throw vehicleError;

      const ids = vehiclesData?.map((v) => v.driver_id).filter(Boolean) || [];
      const { data: profiles, error: profileError } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .in('id', ids.length > 0 ? ids : ['00000000-0000-0000-0000-000000000000']);

      if (profileError) throw profileError;

      const profileMap = new Map<string, { first_name: string | null; last_name: string | null; email: string }>();
      profiles?.forEach((p) => profileMap.set(p.id, p));

      setVehicles(
        (vehiclesData || []).map((v) => {
          const driver = v.driver_id ? profileMap.get(v.driver_id) : null;
          return {
            ...v,
            driver_name: driver
              ? [driver.first_name, driver.last_name].filter(Boolean).join(' ') || driver.email
              : null,
          };
        })
      );
    } catch (err) {
      setError('Failed to load vehicles');
    } finally {
      setLoading(false);
    }
  };

  const filtered = useMemo(() => {
    if (!search.trim()) return vehicles;
    const q = search.toLowerCase();
    return vehicles.filter(
      (v) =>
        v.license_plate.toLowerCase().includes(q) ||
        v.make.toLowerCase().includes(q) ||
        v.model.toLowerCase().includes(q) ||
        (v.driver_name?.toLowerCase() || '').includes(q)
    );
  }, [vehicles, search]);

  const exportCSV = () => {
    const headers = ['Vehicle Model', 'License Plate', 'Assigned Chauffeur', 'Status'];
    const rows = filtered.map((v) => {
      const model = `${v.make} ${v.model} (${v.year} ${v.color})`;
      return [model, v.license_plate, v.driver_name || '--', v.is_active ? 'Active' : 'In Maintenance'];
    });
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `vehicles_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Fleet Management</h1>
          <p>Manage vehicle details, classes, and inspections</p>
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
              placeholder="Search vehicles by plate or model..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="admin-search-input"
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#a1a1aa' }}>Loading vehicles...</div>
        ) : error ? (
          <div style={{ padding: '3rem', textAlign: 'center' }}>
            <p style={{ color: '#ef4444', marginBottom: '1rem' }}>{error}</p>
            <button className="admin-btn" onClick={() => { setError(null); setLoading(true); fetchVehicles(); }}>Try Again</button>
          </div>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th scope="col">Vehicle Model</th>
                <th scope="col">License Plate</th>
                <th scope="col">Assigned Chauffeur</th>
                <th scope="col">Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={4} style={{ textAlign: 'center', padding: '3rem', color: '#a1a1aa' }}>
                    {search ? 'No vehicles match your search.' : 'No vehicles found.'}
                  </td>
                </tr>
              ) : (
                filtered.map((v) => (
                  <tr key={v.id}>
                    <td data-label="Vehicle Model">
                      <div style={{ fontWeight: 500 }}>{v.make} {v.model}</div>
                      <span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>{v.year} {v.color}</span>
                    </td>
                    <td data-label="License Plate"><div style={{ fontFamily: 'monospace' }}>{v.license_plate}</div></td>
                    <td data-label="Assigned Chauffeur">{v.driver_name || '--'}</td>
                    <td data-label="Status">
                      {v.is_active ? (
                        <span className="admin-badge admin-badge-success">Active</span>
                      ) : (
                        <span className="admin-badge admin-badge-warning">In Maintenance</span>
                      )}
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
