import { useState, useEffect, useRef, useCallback } from 'react';
import { NavLink, Outlet, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { supabase } from '../../lib/supabase';
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
import { ToastProvider } from '../../context/ToastContext';
import '../../styles/admin.css';

interface NavItemDef {
  name: string;
  path: string;
  icon: React.ReactNode;
  exact?: boolean;
  badge?: number;
  badgeType?: 'warn' | 'danger' | 'info';
}

interface NavSectionDef {
  title: string;
  items: NavItemDef[];
}

export default function AdminLayout() {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const notifRef = useRef<HTMLDivElement>(null);
  const [counts, setCounts] = useState({
    tickets: 0,
    drivers: 0,
    documents: 0,
  });
  const [readCategories, setReadCategories] = useState<Record<string, boolean>>(() => {
    try {
      const saved = localStorage.getItem('admin_read_notifications');
      return saved ? JSON.parse(saved) : {};
    } catch {
      return {};
    }
  });

  const markCategoryRead = (category: string) => {
    setReadCategories(prev => {
      const updated = { ...prev, [category]: true };
      try {
        localStorage.setItem('admin_read_notifications', JSON.stringify(updated));
      } catch {}
      return updated;
    });
  };

  const markAllRead = () => {
    const updated = { tickets: true, drivers: true, documents: true };
    setReadCategories(updated);
    try {
      localStorage.setItem('admin_read_notifications', JSON.stringify(updated));
    } catch {}
  };

  const isTicketsUnread = counts.tickets > 0 && !readCategories.tickets;
  const isDriversUnread = counts.drivers > 0 && !readCategories.drivers;
  const isDocumentsUnread = counts.documents > 0 && !readCategories.documents;

  const totalUnread = (isTicketsUnread ? 1 : 0) + (isDriversUnread ? 1 : 0) + (isDocumentsUnread ? 1 : 0);
  const totalAlerts = (counts.tickets > 0 ? 1 : 0) + (counts.drivers > 0 ? 1 : 0) + (counts.documents > 0 ? 1 : 0);

  useEffect(() => {
    setSidebarOpen(false);
  }, [location]);

  const fetchCounts = useCallback(async () => {
    try {
      const { data } = await supabase.rpc('get_admin_dashboard_stats');
      if (data) {
        setCounts({
          tickets: data.open_tickets || 0,
          drivers: data.pending_drivers || 0,
          documents: data.pending_documents || 0,
        });
      }
    } catch (err) {
      // Fallback gracefully without throwing
    }
  }, []);

  useEffect(() => {
    fetchCounts();
  }, [location.pathname, fetchCounts]);

  useEffect(() => {
    if (!notifOpen) return;
    const handleClickOutside = (e: MouseEvent) => {
      if (notifRef.current && !notifRef.current.contains(e.target as Node)) {
        setNotifOpen(false);
      }
    };
    document.addEventListener('click', handleClickOutside);
    return () => document.removeEventListener('click', handleClickOutside);
  }, [notifOpen]);

  const handleLogout = async () => {
    await signOut();
    navigate('/admin/login');
  };

  const navSections: NavSectionDef[] = [
    {
      title: 'Operations',
      items: [
        { name: 'Overview', path: '/admin', icon: <LayoutDashboard size={17} />, exact: true },
        { name: 'Journeys', path: '/admin/rides', icon: <Map size={17} /> },
        { 
          name: 'Chauffeurs', 
          path: '/admin/drivers', 
          icon: <CarFront size={17} />
        },
        { name: 'Fleet', path: '/admin/fleet', icon: <Car size={17} /> },
      ]
    },
    {
      title: 'Clientele & Finance',
      items: [
        { name: 'Clients', path: '/admin/users', icon: <Users size={17} /> },
        { name: 'Financial Ledger', path: '/admin/transactions', icon: <WalletCards size={17} /> },
        { name: 'Rates & Pricing', path: '/admin/pricing', icon: <DollarSign size={17} /> },
      ]
    },
    {
      title: 'Concierge & Compliance',
      items: [
        { 
          name: 'Concierge Desk', 
          path: '/admin/support', 
          icon: <Ticket size={17} />,
          badge: counts.tickets > 0 ? counts.tickets : undefined,
          badgeType: 'danger'
        },
        { 
          name: 'Documents', 
          path: '/admin/documents', 
          icon: <FileCheck size={17} />,
          badge: counts.documents > 0 ? counts.documents : undefined,
          badgeType: 'info'
        },
      ]
    }
  ];

  const allNavItems = navSections.flatMap(section => section.items);

  return (
    <ToastProvider>
      <div className="admin-body admin-layout">
      {sidebarOpen && (
        <div
          style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 40, backdropFilter: 'blur(4px)' }}
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Upgraded Sidebar */}
      <aside className={`admin-sidebar ${sidebarOpen ? 'open' : ''}`}>
        
        {/* Brand Header */}
        <div className="admin-sidebar-header">
          <div className="admin-sidebar-logo">
            <img src="/Kenick-logo-favicon.png" alt="Kenick" />
          </div>
          <div className="admin-sidebar-brand">
            <h2>Kenick</h2>
            <span className="admin-sidebar-badge">Concierge Admin</span>
          </div>
        </div>

        {/* Categorized Navigation */}
        <nav className="admin-nav">
          {navSections.map((section) => (
            <div key={section.title} className="admin-nav-section">
              <p className="admin-nav-section-title">{section.title}</p>
              {section.items.map((item) => (
                <NavLink
                  key={item.name}
                  to={item.path}
                  end={item.exact}
                  className={({ isActive }) => `admin-nav-item ${isActive ? 'active' : ''}`}
                >
                  <div className="admin-nav-item-content">
                    {item.icon}
                    <span>{item.name}</span>
                  </div>
                  {item.badge !== undefined && (
                    <span className={`admin-nav-badge admin-nav-badge-${item.badgeType || 'warn'}`}>
                      {item.badge}
                    </span>
                  )}
                </NavLink>
              ))}
            </div>
          ))}
        </nav>

        {/* Executive User Profile Card at Bottom */}
        <div className="admin-user-widget">
          <div className="admin-user-card">
            <div className="admin-user-left">
              <div className="admin-user-avatar">
                {user?.email?.charAt(0).toUpperCase() || 'A'}
              </div>
              <div className="admin-user-details">
                <span className="admin-user-email" title={user?.email || ''}>{user?.email || 'Administrator'}</span>
                <div className="admin-user-role-line">
                  <span className="admin-user-status-dot" />
                  <span>Super Admin</span>
                </div>
              </div>
            </div>
            <button className="admin-user-logout-btn" onClick={handleLogout} title="Sign Out">
              <LogOut size={14} />
            </button>
          </div>
        </div>

      </aside>

      {/* Main Content Area */}
      <main className="admin-main">
        <header className="admin-topbar">
          <div className="admin-topbar-breadcrumb">
            <button 
              className="admin-menu-btn"
              onClick={() => setSidebarOpen(true)}
              aria-label="Toggle navigation sidebar"
            >
              <Menu size={20} />
            </button>
            <span className="admin-topbar-portal-name">Kenick Concierge</span>
            <span className="admin-topbar-divider">/</span>
            <h1 className="admin-topbar-title">
              {allNavItems.find(item => 
                item.exact ? location.pathname === item.path : location.pathname.startsWith(item.path)
              )?.name || 'Dashboard'}
            </h1>
          </div>
          
          <div className="admin-topbar-right">
            <div className="admin-live-status-indicator" title="Live System Active">
              <span className="admin-live-dot" />
            </div>

            <div style={{ position: 'relative' }} ref={notifRef}>
              <button
                className="admin-icon-btn"
                onClick={() => {
                  const next = !notifOpen;
                  setNotifOpen(next);
                  if (next) fetchCounts();
                }}
                title="Notifications & Alerts"
              >
                <Bell size={17} />
                {totalUnread > 0 && (
                  <span className="admin-notif-dot" />
                )}
              </button>

              {notifOpen && (
                <div className="admin-notif-dropdown-clean">
                  <div className="admin-notif-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span style={{ color: '#fff', fontWeight: 600, fontSize: '0.85rem' }}>Operational Alerts</span>
                      {totalUnread > 0 ? (
                        <span style={{ fontSize: '0.68rem', color: 'var(--admin-primary)', background: 'rgba(244, 197, 34, 0.12)', padding: '1px 6px', borderRadius: 4, fontWeight: 600 }}>
                          {totalUnread} unread
                        </span>
                      ) : (
                        <span style={{ fontSize: '0.68rem', color: '#71717a', background: 'rgba(255, 255, 255, 0.04)', padding: '1px 6px', borderRadius: 4 }}>
                          All caught up
                        </span>
                      )}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      {totalUnread > 0 && (
                        <button
                          type="button"
                          onClick={markAllRead}
                          style={{
                            background: 'none',
                            border: 'none',
                            color: 'var(--admin-primary)',
                            cursor: 'pointer',
                            fontSize: '0.72rem',
                            fontWeight: 600,
                            padding: '2px 4px',
                          }}
                          title="Mark all notifications as read"
                        >
                          Mark all read
                        </button>
                      )}
                      <button 
                        onClick={() => setNotifOpen(false)} 
                        style={{ background: 'none', border: 'none', color: '#71717a', cursor: 'pointer', fontSize: '18px', lineHeight: 1 }}
                      >
                        &times;
                      </button>
                    </div>
                  </div>
                  
                  <div>
                    {counts.tickets > 0 && (
                      <NavLink 
                        to="/admin/support" 
                        className={`admin-notif-item ${!isTicketsUnread ? 'is-read' : ''}`}
                        onClick={() => {
                          markCategoryRead('tickets');
                          setNotifOpen(false);
                        }}
                      >
                        <div 
                          style={{ 
                            width: 8, 
                            height: 8, 
                            borderRadius: '50%', 
                            background: isTicketsUnread ? 'var(--admin-danger)' : '#52525b',
                            marginTop: 6,
                            flexShrink: 0
                          }} 
                        />
                        <div style={{ flex: 1 }}>
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 6 }}>
                            <p style={{ margin: 0, fontSize: '0.82rem', fontWeight: isTicketsUnread ? 600 : 500, color: isTicketsUnread ? '#fff' : '#a1a1aa' }}>
                              Support Inquiries
                            </p>
                            {!isTicketsUnread ? (
                              <span style={{ fontSize: '0.66rem', color: '#71717a', background: 'rgba(255,255,255,0.04)', padding: '1px 6px', borderRadius: 4 }}>
                                Read
                              </span>
                            ) : (
                              <span style={{ fontSize: '0.66rem', color: 'var(--admin-danger)', background: 'rgba(239, 68, 68, 0.12)', padding: '1px 6px', borderRadius: 4, fontWeight: 600 }}>
                                New
                              </span>
                            )}
                          </div>
                          <p style={{ margin: '2px 0 0', fontSize: '0.72rem', color: '#71717a' }}>{counts.tickets} client ticket(s) awaiting response</p>
                        </div>
                      </NavLink>
                    )}

                    {counts.drivers > 0 && (
                      <NavLink 
                        to="/admin/drivers" 
                        className={`admin-notif-item ${!isDriversUnread ? 'is-read' : ''}`}
                        onClick={() => {
                          markCategoryRead('drivers');
                          setNotifOpen(false);
                        }}
                      >
                        <div 
                          style={{ 
                            width: 8, 
                            height: 8, 
                            borderRadius: '50%', 
                            background: isDriversUnread ? 'var(--admin-warning)' : '#52525b',
                            marginTop: 6,
                            flexShrink: 0
                          }} 
                        />
                        <div style={{ flex: 1 }}>
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 6 }}>
                            <p style={{ margin: 0, fontSize: '0.82rem', fontWeight: isDriversUnread ? 600 : 500, color: isDriversUnread ? '#fff' : '#a1a1aa' }}>
                              Chauffeur Approvals
                            </p>
                            {!isDriversUnread ? (
                              <span style={{ fontSize: '0.66rem', color: '#71717a', background: 'rgba(255,255,255,0.04)', padding: '1px 6px', borderRadius: 4 }}>
                                Read
                              </span>
                            ) : (
                              <span style={{ fontSize: '0.66rem', color: 'var(--admin-warning)', background: 'rgba(245, 158, 11, 0.12)', padding: '1px 6px', borderRadius: 4, fontWeight: 600 }}>
                                New
                              </span>
                            )}
                          </div>
                          <p style={{ margin: '2px 0 0', fontSize: '0.72rem', color: '#71717a' }}>{counts.drivers} application(s) pending review</p>
                        </div>
                      </NavLink>
                    )}

                    {counts.documents > 0 && (
                      <NavLink 
                        to="/admin/documents" 
                        className={`admin-notif-item ${!isDocumentsUnread ? 'is-read' : ''}`}
                        onClick={() => {
                          markCategoryRead('documents');
                          setNotifOpen(false);
                        }}
                      >
                        <div 
                          style={{ 
                            width: 8, 
                            height: 8, 
                            borderRadius: '50%', 
                            background: isDocumentsUnread ? 'var(--admin-info)' : '#52525b',
                            marginTop: 6,
                            flexShrink: 0
                          }} 
                        />
                        <div style={{ flex: 1 }}>
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 6 }}>
                            <p style={{ margin: 0, fontSize: '0.82rem', fontWeight: isDocumentsUnread ? 600 : 500, color: isDocumentsUnread ? '#fff' : '#a1a1aa' }}>
                              Document Verifications
                            </p>
                            {!isDocumentsUnread ? (
                              <span style={{ fontSize: '0.66rem', color: '#71717a', background: 'rgba(255,255,255,0.04)', padding: '1px 6px', borderRadius: 4 }}>
                                Read
                              </span>
                            ) : (
                              <span style={{ fontSize: '0.66rem', color: 'var(--admin-info)', background: 'rgba(59, 130, 246, 0.12)', padding: '1px 6px', borderRadius: 4, fontWeight: 600 }}>
                                New
                              </span>
                            )}
                          </div>
                          <p style={{ margin: '2px 0 0', fontSize: '0.72rem', color: '#71717a' }}>{counts.documents} document proof(s) to verify</p>
                        </div>
                      </NavLink>
                    )}

                    {totalAlerts === 0 && (
                      <div style={{ padding: '2.5rem 1.5rem', textAlign: 'center', color: '#71717a', fontSize: '0.82rem' }}>
                        All queues nominal. No pending alerts.
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        <div className="admin-content">
          <Outlet />
        </div>
      </main>
    </div>
    </ToastProvider>
  );
}
