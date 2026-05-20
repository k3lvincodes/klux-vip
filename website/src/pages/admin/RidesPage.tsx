import { Filter, Search, Download } from 'lucide-react';

export default function RidesPage() {
  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Ride History & Dispatch</h1>
          <p>Live tracking and historical records of all trips</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="admin-btn admin-btn-outline">
            <Filter size={16} />
            Filter
          </button>
          <button className="admin-btn">
            <Download size={16} />
            Export Data
          </button>
        </div>
      </div>

      <div className="admin-table-wrapper">
        <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', gap: '1rem' }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input 
              type="text" 
              placeholder="Search by ID or passenger..." 
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        <table className="admin-table">
          <thead>
            <tr>
              <th>Ride ID</th>
              <th>Passenger</th>
              <th>Driver</th>
              <th>Fare</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#REQ-8921</div></td>
              <td><div style={{ fontWeight: 500 }}>John Doe</div></td>
              <td>Alex Johnson</td>
              <td>$45.00</td>
              <td><span className="admin-badge admin-badge-success">Completed</span></td>
            </tr>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#REQ-8922</div></td>
              <td><div style={{ fontWeight: 500 }}>Emma Wilson</div></td>
              <td>Sarah Williams</td>
              <td>$120.50</td>
              <td><span className="admin-badge admin-badge-info">In Progress</span></td>
            </tr>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#REQ-8923</div></td>
              <td><div style={{ fontWeight: 500 }}>Michael Brown</div></td>
              <td>--</td>
              <td>$32.00</td>
              <td><span className="admin-badge admin-badge-warning">Looking for Driver</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
