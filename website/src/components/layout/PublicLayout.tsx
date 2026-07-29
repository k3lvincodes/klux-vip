import { Outlet, useLocation } from 'react-router-dom';
import Navbar from './Navbar';
import Footer from './Footer';

export default function PublicLayout() {
  const location = useLocation();
  const isBookPage = location.pathname === '/book';

  return (
    <>
      <Navbar />
      <main>
        <Outlet />
      </main>
      {!isBookPage && <Footer />}
    </>
  );
}
