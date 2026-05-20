import { Plus, Search, Filter } from 'lucide-react';

export default function VehiclesPage() {
  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Fleet Management</h1>
          <p>Manage vehicle details, classes, and inspections</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="admin-btn admin-btn-outline">
            <Filter size={16} />
            Filter
          </button>
          <button className="admin-btn">
            <Plus size={16} />
            Add Vehicle
          </button>
        </div>
      </div>

      <div className="admin-table-wrapper">
        <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', gap: '1rem' }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input 
              type="text" 
              placeholder="Search vehicles by plate or model..." 
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        <table className="admin-table">
          <thead>
            <tr>
              <th>Vehicle Model</th>
              <th>License Plate</th>
              <th>Class</th>
              <th>Assigned Driver</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><div style={{ fontWeight: 500 }}>Mercedes-Benz S-Class</div><span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>2024 Black</span></td>
              <td><div style={{ fontFamily: 'monospace' }}>VIP-001</div></td>
              <td>First Class</td>
              <td>Alex Johnson</td>
              <td><span className="admin-badge admin-badge-success">Active</span></td>
            </tr>
            <tr>
              <td><div style={{ fontWeight: 500 }}>BMW 7 Series</div><span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>2023 White</span></td>
              <td><div style={{ fontFamily: 'monospace' }}>VIP-042</div></td>
              <td>Business Class</td>
              <td>Sarah Williams</td>
              <td><span className="admin-badge admin-badge-success">Active</span></td>
            </tr>
            <tr>
              <td><div style={{ fontWeight: 500 }}>Cadillac Escalade</div><span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>2024 Black</span></td>
              <td><div style={{ fontFamily: 'monospace' }}>VIP-015</div></td>
              <td>SUV VIP</td>
              <td>--</td>
              <td><span className="admin-badge admin-badge-warning">In Maintenance</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
