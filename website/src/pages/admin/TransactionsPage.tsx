import { Search, Filter, Download } from 'lucide-react';

export default function TransactionsPage() {
  return (
    <div>
      <div className="admin-page-header">
        <div>
          <h1>Transaction Ledger</h1>
          <p>Track ride payments, driver payouts, and platform fees</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="admin-btn admin-btn-outline">
            <Filter size={16} />
            Filter
          </button>
          <button className="admin-btn">
            <Download size={16} />
            Export CSV
          </button>
        </div>
      </div>

      <div className="admin-table-wrapper">
        <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', gap: '1rem' }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <Search size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#a1a1aa' }} />
            <input 
              type="text" 
              placeholder="Search transactions..." 
              style={{ width: '100%', padding: '0.6rem 1rem 0.6rem 2.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff', outline: 'none' }}
            />
          </div>
        </div>

        <table className="admin-table">
          <thead>
            <tr>
              <th>Transaction ID</th>
              <th>Type</th>
              <th>From / To</th>
              <th>Amount</th>
              <th>Date</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#TXN-90142</div></td>
              <td>Ride Payment</td>
              <td>
                <div style={{ fontWeight: 500 }}>John Doe → Alex Johnson</div>
                <span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>Ride #REQ-8921</span>
              </td>
              <td style={{ fontWeight: 600, color: '#10b981' }}>+$45.00</td>
              <td>May 20, 2026</td>
              <td><span className="admin-badge admin-badge-success">Settled</span></td>
            </tr>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#TXN-90141</div></td>
              <td>Driver Payout</td>
              <td>
                <div style={{ fontWeight: 500 }}>Platform → Sarah Williams</div>
                <span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>Weekly payout</span>
              </td>
              <td style={{ fontWeight: 600, color: '#ef4444' }}>-$1,250.00</td>
              <td>May 19, 2026</td>
              <td><span className="admin-badge admin-badge-success">Settled</span></td>
            </tr>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#TXN-90140</div></td>
              <td>Ride Payment</td>
              <td>
                <div style={{ fontWeight: 500 }}>Emma Wilson → Sarah Williams</div>
                <span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>Ride #REQ-8922</span>
              </td>
              <td style={{ fontWeight: 600, color: '#10b981' }}>+$120.50</td>
              <td>May 20, 2026</td>
              <td><span className="admin-badge admin-badge-warning">Pending</span></td>
            </tr>
            <tr>
              <td><div style={{ fontFamily: 'monospace', color: '#a1a1aa' }}>#TXN-90139</div></td>
              <td>Refund</td>
              <td>
                <div style={{ fontWeight: 500 }}>Platform → Michael Brown</div>
                <span style={{ fontSize: '0.8rem', color: '#a1a1aa' }}>Cancelled ride refund</span>
              </td>
              <td style={{ fontWeight: 600, color: '#ef4444' }}>-$32.00</td>
              <td>May 18, 2026</td>
              <td><span className="admin-badge admin-badge-info">Processing</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
