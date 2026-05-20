import { Plus, Search, Filter } from 'lucide-react';

export default function UsersPage() {
  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>User Management</h1>
          <p>View and manage all registered passengers</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="admin-btn admin-btn-outline">
            <Filter size={16} />
            Filter
          </button>
          <button className="admin-btn">
            <Plus size={16} />
            Add User
          </button>
        </div>
      </div>

      <div className="admin-table-wrapper">
        <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', gap: '1rem' }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input 
              type="text" 
              placeholder="Search by name or email..." 
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        <table className="admin-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Joined Date</th>
              <th>Total Rides</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {/* Placeholder rows */}
            <tr>
              <td><div style={{ fontWeight: 500 }}>John Doe</div></td>
              <td>john.doe@example.com</td>
              <td>May 15, 2026</td>
              <td>12</td>
              <td><span className="admin-badge admin-badge-success">Active</span></td>
            </tr>
            <tr>
              <td><div style={{ fontWeight: 500 }}>Jane Smith</div></td>
              <td>jane.smith@example.com</td>
              <td>May 18, 2026</td>
              <td>4</td>
              <td><span className="admin-badge admin-badge-success">Active</span></td>
            </tr>
            <tr>
              <td><div style={{ fontWeight: 500 }}>Michael Brown</div></td>
              <td>michael.b@example.com</td>
              <td>May 20, 2026</td>
              <td>0</td>
              <td><span className="admin-badge admin-badge-warning">Unverified</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
