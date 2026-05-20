import { Search, Filter, Eye, CheckCircle, XCircle } from 'lucide-react';

export default function DocumentsPage() {
  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Document Verification</h1>
          <p>Review and approve driver licenses, insurance, and background checks</p>
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
              placeholder="Search by driver name..." 
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        <table className="admin-table">
          <thead>
            <tr>
              <th>Driver</th>
              <th>Document Type</th>
              <th>Submitted</th>
              <th>Expiry</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><div style={{ fontWeight: 500 }}>David Clark</div></td>
              <td>Driver's License</td>
              <td>May 18, 2026</td>
              <td>Dec 15, 2028</td>
              <td><span className="admin-badge admin-badge-warning">Pending Review</span></td>
              <td>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button className="admin-btn admin-btn-outline" style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem' }}><Eye size={14} /></button>
                  <button style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem', background: 'var(--admin-success-dim)', color: 'var(--admin-success)', border: '1px solid rgba(16,185,129,0.2)', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center' }}><CheckCircle size={14} /></button>
                  <button style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem', background: 'var(--admin-danger-dim)', color: 'var(--admin-danger)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center' }}><XCircle size={14} /></button>
                </div>
              </td>
            </tr>
            <tr>
              <td><div style={{ fontWeight: 500 }}>David Clark</div></td>
              <td>Vehicle Insurance</td>
              <td>May 18, 2026</td>
              <td>May 18, 2027</td>
              <td><span className="admin-badge admin-badge-warning">Pending Review</span></td>
              <td>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button className="admin-btn admin-btn-outline" style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem' }}><Eye size={14} /></button>
                  <button style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem', background: 'var(--admin-success-dim)', color: 'var(--admin-success)', border: '1px solid rgba(16,185,129,0.2)', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center' }}><CheckCircle size={14} /></button>
                  <button style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem', background: 'var(--admin-danger-dim)', color: 'var(--admin-danger)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center' }}><XCircle size={14} /></button>
                </div>
              </td>
            </tr>
            <tr>
              <td><div style={{ fontWeight: 500 }}>Alex Johnson</div></td>
              <td>Background Check</td>
              <td>Apr 02, 2026</td>
              <td>Apr 02, 2027</td>
              <td><span className="admin-badge admin-badge-success">Verified</span></td>
              <td>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button className="admin-btn admin-btn-outline" style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem' }}><Eye size={14} /></button>
                </div>
              </td>
            </tr>
            <tr>
              <td><div style={{ fontWeight: 500 }}>Sarah Williams</div></td>
              <td>Driver's License</td>
              <td>Mar 10, 2026</td>
              <td>Jan 30, 2028</td>
              <td><span className="admin-badge admin-badge-success">Verified</span></td>
              <td>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button className="admin-btn admin-btn-outline" style={{ padding: '0.4rem 0.6rem', fontSize: '0.8rem' }}><Eye size={14} /></button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
