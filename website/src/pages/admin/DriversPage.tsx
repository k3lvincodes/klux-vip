import { Filter, Search, UserCheck } from 'lucide-react';

export default function DriversPage() {
  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Driver Operations</h1>
          <p>Manage driver profiles, approvals, and statuses</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="admin-btn admin-btn-outline">
            <Filter size={16} />
            Filter
          </button>
          <button className="admin-btn">
            <UserCheck size={16} />
            Pending Approvals
          </button>
        </div>
      </div>

      <div className="admin-table-wrapper">
        <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', gap: '1rem' }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input 
              type="text" 
              placeholder="Search drivers..." 
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        <table className="admin-table">
          <thead>
            <tr>
              <th>Driver</th>
              <th>Vehicle</th>
              <th>Rating</th>
              <th>Completed Rides</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><div style={{ fontWeight: 500 }}>Alex Johnson</div></td>
              <td>Mercedes S-Class (VIP-001)</td>
              <td>⭐ 4.9</td>
              <td>342</td>
              <td><span className="admin-badge admin-badge-success">Online</span></td>
            </tr>
            <tr>
              <td><div style={{ fontWeight: 500 }}>Sarah Williams</div></td>
              <td>BMW 7 Series (VIP-042)</td>
              <td>⭐ 4.8</td>
              <td>128</td>
              <td><span className="admin-badge admin-badge-info">En Route</span></td>
            </tr>
            <tr>
              <td><div style={{ fontWeight: 500 }}>David Clark</div></td>
              <td>Audi A8 (VIP-015)</td>
              <td>⭐ 5.0</td>
              <td>45</td>
              <td><span className="admin-badge admin-badge-warning">Pending Auth</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
