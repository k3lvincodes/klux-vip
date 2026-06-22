import { Navigate, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export const ProtectedRoute = () => {
  const { user, isSuperAdmin, loading } = useAuth();
  const navigate = useNavigate();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen w-full bg-[#030303]">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-[#F4C522]"></div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/admin/login" replace />;
  }

  if (!isSuperAdmin) {
    return (
      <div className="flex flex-col items-center justify-center h-screen w-full bg-[#030303] text-white">
        <h1 className="text-3xl font-bold mb-4">Access Denied</h1>
        <p className="text-gray-400 mb-8">You do not have super admin privileges.</p>
        <button 
          onClick={() => navigate('/')}
          className="bg-[#F4C522] text-black font-semibold py-2 px-6 rounded-full"
        >
          Return to Home
        </button>
      </div>
    );
  }

  return <Outlet />;
};
