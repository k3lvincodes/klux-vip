import { Navigate, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

export const ProtectedRoute = () => {
  const { user, isSuperAdmin, loading } = useAuth();
  const navigate = useNavigate();

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', width: '100%', background: '#030303' }}>
        <div style={{ width: '48px', height: '48px', borderRadius: '50%', border: '3px solid transparent', borderTopColor: '#F4C522', borderBottomColor: '#F4C522', animation: 'spin 1s linear infinite' }} />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/admin/login" replace />;
  }

  if (!isSuperAdmin) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100vh', width: '100%', background: '#030303', color: '#fff' }}>
        <h1 style={{ fontSize: '1.875rem', fontWeight: 700, marginBottom: '1rem' }}>Access Denied</h1>
        <p style={{ color: '#9ca3af', marginBottom: '2rem' }}>You do not have super admin privileges.</p>
        <button
          onClick={() => navigate('/')}
          style={{ background: '#F4C522', color: '#000', fontWeight: 600, paddingTop: '0.5rem', paddingBottom: '0.5rem', paddingLeft: '1.5rem', paddingRight: '1.5rem', borderRadius: '9999px', border: 'none', cursor: 'pointer' }}
        >
          Return to Home
        </button>
      </div>
    );
  }

  return <Outlet />;
};
