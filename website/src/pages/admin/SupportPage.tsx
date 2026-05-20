import { Search, Filter, MessageSquare } from 'lucide-react';

export default function SupportPage() {
  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Support Desk</h1>
          <p>Customer and driver support tickets</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="admin-btn admin-btn-outline">
            <Filter size={16} />
            Filter
          </button>
        </div>
      </div>

      <div className="admin-table-wrapper">
        <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', gap: '1rem' }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input 
              type="text" 
              placeholder="Search tickets..." 
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        <table className="admin-table">
          <thead>
            <tr>
              <th>Ticket ID</th>
              <th>Subject</th>
              <th>User</th>
              <th>Last Updated</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#TK-1042</div></td>
              <td><div style={{ fontWeight: 500 }}>Payment failed for ride #REQ-8921</div></td>
              <td>John Doe</td>
              <td>10 mins ago</td>
              <td><span className="admin-badge admin-badge-danger">Open</span></td>
              <td><button className="admin-btn admin-btn-outline" style={{ padding: '0.4rem 0.8rem', fontSize: '0.8rem' }}><MessageSquare size={14} /> View</button></td>
            </tr>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#TK-1041</div></td>
              <td><div style={{ fontWeight: 500 }}>Lost item in vehicle</div></td>
              <td>Emma Wilson</td>
              <td>2 hours ago</td>
              <td><span className="admin-badge admin-badge-warning">Pending</span></td>
              <td><button className="admin-btn admin-btn-outline" style={{ padding: '0.4rem 0.8rem', fontSize: '0.8rem' }}><MessageSquare size={14} /> View</button></td>
            </tr>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#TK-1038</div></td>
              <td><div style={{ fontWeight: 500 }}>Driver didn't arrive</div></td>
              <td>Michael Brown</td>
              <td>1 day ago</td>
              <td><span className="admin-badge admin-badge-success">Resolved</span></td>
              <td><button className="admin-btn admin-btn-outline" style={{ padding: '0.4rem 0.8rem', fontSize: '0.8rem' }}><MessageSquare size={14} /> View</button></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
