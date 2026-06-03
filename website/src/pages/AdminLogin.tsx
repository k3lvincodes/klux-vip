import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { ArrowRight, Eye, EyeOff } from 'lucide-react';
import '../styles/admin-login.css';

export default function AdminLogin() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [mounted, setMounted] = useState(false);
  const navigate = useNavigate();
  const { user, isSuperAdmin } = useAuth();

  useEffect(() => {
    setMounted(true);
  }, []);

  if (user && isSuperAdmin) {
    navigate('/admin');
    return null;
  }

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (authError) throw authError;

      if (data.user) {
        const { data: userData, error: userError } = await supabase
          .from('profiles')
          .select('is_super_admin')
          .eq('id', data.user.id)
          .single();

        if (userError) throw userError;

        if (userData?.is_super_admin) {
          navigate('/admin');
        } else {
          await supabase.auth.signOut();
          setError('Access denied. Super admin privileges required.');
        }
      }
    } catch (err: any) {
      setError(err.message || 'Authentication failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="al-page">
      {/* LEFT PANEL — Brand Visual */}
      <div className="al-brand-panel">
        {/* Logo at top left */}
        <div className="al-top-logo">
          <img src="/Kenick-logo-favicon.png" alt="Kenick" />
        </div>
        {/* Animated aurora blobs */}
        <div className="al-aurora">
          <div className="al-aurora-blob al-blob-1"></div>
          <div className="al-aurora-blob al-blob-2"></div>
          <div className="al-aurora-blob al-blob-3"></div>
        </div>
        {/* Dot grid overlay */}
        <div className="al-dot-grid"></div>
        {/* Noise texture */}
        <div className="al-noise"></div>

        <div className={`al-brand-content ${mounted ? 'al-visible' : ''}`}>
          <h1 className="al-brand-title">
            Kenick Transportation<br />
            <span>Command Center</span>
          </h1>
          <p className="al-brand-desc">
            Full platform control. Monitor rides, manage chauffeurs, 
            review transactions, and oversee every aspect of the 
            Kenick VIP experience.
          </p>
          <div className="al-brand-stats">
            <div className="al-stat">
              <span className="al-stat-value">24/7</span>
              <span className="al-stat-label">Monitoring</span>
            </div>
            <div className="al-stat-divider"></div>
            <div className="al-stat">
              <span className="al-stat-value">100%</span>
              <span className="al-stat-label">Encrypted</span>
            </div>
            <div className="al-stat-divider"></div>
            <div className="al-stat">
              <span className="al-stat-value">Real-time</span>
              <span className="al-stat-label">Analytics</span>
            </div>
          </div>
        </div>
      </div>

      {/* RIGHT PANEL — Login Form */}
      <div className="al-form-panel">
        <div className={`al-form-container ${mounted ? 'al-visible' : ''}`}>
          <div className="al-form-header">
            <h2>Welcome back</h2>
            <p>Enter your credentials to access the admin dashboard</p>
          </div>

          {error && (
            <div className="al-error">
              <div className="al-error-dot"></div>
              {error}
            </div>
          )}

          <form className="al-form" onSubmit={handleLogin}>
            {/* Email Field */}
            <div className="al-field">
              <label htmlFor="al-email">Email address</label>
              <input
                id="al-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@kenick.com"
                autoComplete="email"
                required
              />
              <div className="al-field-line"></div>
            </div>

            {/* Password Field */}
            <div className="al-field">
              <label htmlFor="al-password">Password</label>
              <div className="al-password-wrap">
                <input
                  id="al-password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••"
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  className="al-eye-btn"
                  onClick={() => setShowPassword(!showPassword)}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
              <div className="al-field-line"></div>
            </div>

            {/* Submit */}
            <button type="submit" className="al-submit" disabled={loading}>
              {loading ? (
                <div className="al-loader">
                  <div className="al-loader-bar"></div>
                </div>
              ) : (
                <>
                  <span>Sign in to Dashboard</span>
                  <ArrowRight size={18} />
                </>
              )}
            </button>
          </form>

          <div className="al-footer">
            <a href="/">← Back to kenicktransportation.com</a>
          </div>
        </div>
      </div>
    </div>
  );
}
