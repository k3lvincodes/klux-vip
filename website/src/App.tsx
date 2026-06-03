import { Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import BookingPage from './pages/BookingPage';
import PrivacyPolicy from './pages/PrivacyPolicy';
import TermsConditions from './pages/TermsConditions';
import CookiesPage from './pages/CookiesPage';
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
import PricingPage from './pages/admin/PricingPage';
import UserDetail from './pages/admin/UserDetail';
import { ProtectedRoute } from './components/ProtectedRoute';
import PublicLayout from './components/PublicLayout';

function App() {
  return (
    <Routes>
      {/* Public Pages */}
      <Route element={<PublicLayout />}>
        <Route path="/" element={<LandingPage />} />
        <Route path="/book" element={<BookingPage />} />
        <Route path="/privacy" element={<PrivacyPolicy />} />
        <Route path="/terms" element={<TermsConditions />} />
        <Route path="/cookies" element={<CookiesPage />} />
      </Route>
      
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
          <Route path="pricing" element={<PricingPage />} />
        </Route>
      </Route>
    </Routes>
  );
}

export default App;
