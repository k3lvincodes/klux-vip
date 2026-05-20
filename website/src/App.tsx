import { Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import AdminLogin from './pages/AdminLogin';
import AdminLayout from './pages/admin/AdminLayout';
import Overview from './pages/admin/Overview';
import UsersPage from './pages/admin/UsersPage';
import DriversPage from './pages/admin/DriversPage';
import RidesPage from './pages/admin/RidesPage';
import VehiclesPage from './pages/admin/VehiclesPage';
import SupportPage from './pages/admin/SupportPage';
import TransactionsPage from './pages/admin/TransactionsPage';
import DocumentsPage from './pages/admin/DocumentsPage';
import UserDetail from './pages/admin/UserDetail';
import { ProtectedRoute } from './components/ProtectedRoute';

function App() {
  return (
    <Routes>
      {/* Public Landing Page */}
      <Route path="/" element={<LandingPage />} />
      
      {/* Admin Login */}
      <Route path="/admin/login" element={<AdminLogin />} />

      {/* Protected Admin Dashboard */}
      <Route path="/admin" element={<ProtectedRoute />}>
        <Route element={<AdminLayout />}>
          <Route index element={<Overview />} />
          <Route path="users" element={<UsersPage />} />
          <Route path="users/:id" element={<UserDetail />} />
          <Route path="drivers" element={<DriversPage />} />
          <Route path="rides" element={<RidesPage />} />
          <Route path="vehicles" element={<VehiclesPage />} />
          <Route path="support" element={<SupportPage />} />
          <Route path="transactions" element={<TransactionsPage />} />
          <Route path="documents" element={<DocumentsPage />} />
        </Route>
      </Route>
    </Routes>
  );
}

export default App;
