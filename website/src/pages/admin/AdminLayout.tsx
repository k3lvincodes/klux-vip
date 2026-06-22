import { useState, useEffect } from 'react';
import { NavLink, Outlet, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { 
  LayoutDashboard, 
  Users, 
  CarFront, 
  Map, 
  Car, 
  Ticket, 
  WalletCards, 
  FileCheck,
  DollarSign,
  Menu,
  Bell,
  LogOut
} from 'lucide-react';
import '../../styles/admin.css';

export default function AdminLayout() {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    setSidebarOpen(false);
  }, [location]);

  const handleLogout = async () => {
    await signOut();
    navigate('/admin/login');
  };

  const navItems = [
    { name: 'Overview', path: '/admin', icon: <LayoutDashboard size={18} />, exact: true },
    { name: 'Users', path: '/admin/users', icon: <Users size={18} /> },
    { name: 'Chauffeurs', path: '/admin/drivers', icon: <CarFront size={18} /> },
    { name: 'Rides', path: '/admin/rides', icon: <Map size={18} /> },
    { name: 'Vehicles', path: '/admin/vehicles', icon: <Car size={18} /> },
    { name: 'Support', path: '/admin/support', icon: <Ticket size={18} /> },
    { name: 'Transactions', path: '/admin/transactions', icon: <WalletCards size={18} /> },
    { name: 'Documents', path: '/admin/documents', icon: <FileCheck size={18} /> },
    { name: 'Pricing', path: '/admin/pricing', icon: <DollarSign size={18} /> },
  ];

  return (
    <div className="admin-body admin-layout">
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/60 z-40 lg:hidden backdrop-blur-sm"
          style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 40, backdropFilter: 'blur(4px)' }}
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <aside className={`admin-sidebar ${sidebarOpen ? 'open' : ''}`}>
        <div className="admin-sidebar-header">
          <img src="/Kenick-logo-favicon.png" alt="Kenick" />
          <h2>Kenick Admin</h2>
        </div>

        <nav className="admin-nav">
          {navItems.map((item) => (
            <NavLink
              key={item.name}
              to={item.path}
              end={item.exact}
              className={({ isActive }) => `admin-nav-item ${isActive ? 'active' : ''}`}
            >
              {item.icon}
              {item.name}
            </NavLink>
          ))}
        </nav>

        <div className="admin-user-widget">
          <div className="admin-user-info">
            <div className="admin-user-avatar">
              {user?.email?.charAt(0).toUpperCase() || 'A'}
            </div>
            <div className="admin-user-details">
              <p className="admin-user-email">{user?.email}</p>
              <p className="admin-user-role">Super Admin</p>
            </div>
          </div>
          <button className="admin-logout-btn" onClick={handleLogout} title="Sign out">
            <LogOut size={18} />
          </button>
        </div>
      </aside>

      <main className="admin-main">
        <header className="admin-topbar">
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <button 
              className="admin-menu-btn"
              style={{ background: 'none', border: 'none', color: '#a1a1aa', cursor: 'pointer' }}
              onClick={() => setSidebarOpen(true)}
            >
              <Menu size={24} />
            </button>
            <h1 className="admin-topbar-title">
              {navItems.find(item => 
                item.exact ? location.pathname === item.path : location.pathname.startsWith(item.path)
              )?.name || 'Dashboard'}
            </h1>
          </div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <button style={{ background: 'none', border: 'none', color: '#a1a1aa', cursor: 'pointer', position: 'relative' }}>
              <Bell size={20} />
              <span style={{ position: 'absolute', top: 0, right: 0, width: '8px', height: '8px', backgroundColor: '#ef4444', borderRadius: '50%', border: '2px solid #09090b' }}></span>
            </button>
          </div>
        </header>

        <div className="admin-content">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
