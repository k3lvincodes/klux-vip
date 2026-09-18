import { useState, useEffect, useRef } from 'react';
import { useNavigate, Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { ArrowRight, Eye, EyeOff, Mail, Lock, ShieldCheck, AlertCircle } from 'lucide-react';
import '../styles/admin-login.css';

export default function AdminLogin() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [mounted, setMounted] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const navigate = useNavigate();
  const { user, isSuperAdmin, loading: authLoading } = useAuth();

  useEffect(() => {
    setMounted(true);
  }, []);

  // Animated Background Effect (inspired by animatedbackgrounds.me)
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animId: number;
    let width = (canvas.width = canvas.parentElement?.clientWidth || window.innerWidth);
    let height = (canvas.height = canvas.parentElement?.clientHeight || window.innerHeight);

    const handleResize = () => {
      if (!canvas) return;
      width = canvas.width = canvas.parentElement?.clientWidth || window.innerWidth;
      height = canvas.height = canvas.parentElement?.clientHeight || window.innerHeight;
    };

    window.addEventListener('resize', handleResize);

    // Particle nodes configuration
    const particleCount = 42;
    const particles: Array<{
      x: number;
      y: number;
      vx: number;
      vy: number;
      radius: number;
      baseAlpha: number;
      pulseSpeed: number;
      pulseAngle: number;
    }> = [];

    for (let i = 0; i < particleCount; i++) {
      particles.push({
        x: Math.random() * width,
        y: Math.random() * height,
        vx: (Math.random() - 0.5) * 0.45,
        vy: (Math.random() - 0.5) * 0.45,
        radius: Math.random() * 2 + 1,
        baseAlpha: Math.random() * 0.4 + 0.2,
        pulseSpeed: Math.random() * 0.02 + 0.01,
        pulseAngle: Math.random() * Math.PI * 2,
      });
    }

    let mouseX = -1000;
    let mouseY = -1000;

    const handleMouseMove = (e: MouseEvent) => {
      const rect = canvas.getBoundingClientRect();
      mouseX = e.clientX - rect.left;
      mouseY = e.clientY - rect.top;
    };

    const handleMouseLeave = () => {
      mouseX = -1000;
      mouseY = -1000;
    };

    canvas.parentElement?.addEventListener('mousemove', handleMouseMove);
    canvas.parentElement?.addEventListener('mouseleave', handleMouseLeave);

    const render = () => {
      ctx.clearRect(0, 0, width, height);

      // Update and draw particles
      for (let i = 0; i < particles.length; i++) {
        const p = particles[i];

        // Move
        p.x += p.vx;
        p.y += p.vy;

        // Bounce at boundaries
        if (p.x < 0 || p.x > width) p.vx *= -1;
        if (p.y < 0 || p.y > height) p.vy *= -1;

        // Mouse gentle interaction
        const dxMouse = mouseX - p.x;
        const dyMouse = mouseY - p.y;
        const distMouse = Math.sqrt(dxMouse * dxMouse + dyMouse * dyMouse);
        if (distMouse < 120 && distMouse > 0) {
          const force = (120 - distMouse) / 120;
          p.x -= (dxMouse / distMouse) * force * 0.8;
          p.y -= (dyMouse / distMouse) * force * 0.8;
        }

        // Pulse alpha
        p.pulseAngle += p.pulseSpeed;
        const alpha = p.baseAlpha + Math.sin(p.pulseAngle) * 0.15;

        // Draw particle
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(244, 197, 34, ${Math.max(0.1, alpha)})`;
        ctx.shadowColor = 'rgba(244, 197, 34, 0.4)';
        ctx.shadowBlur = 8;
        ctx.fill();
        ctx.shadowBlur = 0;

        // Connect nearby particles
        for (let j = i + 1; j < particles.length; j++) {
          const p2 = particles[j];
          const dx = p.x - p2.x;
          const dy = p.y - p2.y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < 110) {
            const lineAlpha = (1 - dist / 110) * 0.16;
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(p2.x, p2.y);
            ctx.strokeStyle = `rgba(244, 197, 34, ${lineAlpha})`;
            ctx.lineWidth = 0.8;
            ctx.stroke();
          }
        }
      }

      animId = requestAnimationFrame(render);
    };

    render();

    return () => {
      cancelAnimationFrame(animId);
      window.removeEventListener('resize', handleResize);
      canvas.parentElement?.removeEventListener('mousemove', handleMouseMove);
      canvas.parentElement?.removeEventListener('mouseleave', handleMouseLeave);
    };
  }, []);

  if (authLoading) {
    return (
      <div className="al-page">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: '100%', height: '100vh' }}>
          <div className="al-loader"><div className="al-loader-bar"></div></div>
        </div>
      </div>
    );
  }

  if (user && isSuperAdmin) {
    return <Navigate to="/admin" replace />;
  }

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);

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
          navigate('/admin', { replace: true });
        } else {
          await supabase.auth.signOut();
          setError('Access denied. Super admin privileges required.');
        }
      }
    } catch (err: any) {
      setError(err.message || 'Authentication failed. Please check your credentials.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="al-page">
      {/* Ambient background animated glowing orbs */}
      <div className="al-ambient-bg">
        <div className="al-ambient-orb al-orb-1" />
        <div className="al-ambient-orb al-orb-2" />
        <div className="al-ambient-orb al-orb-3" />
      </div>

      {/* Logo at top left */}
      <div className="al-top-logo">
        <img src="/Kenick-logo-favicon.png" alt="Kenick Executive Portal" />
      </div>

      {/* LEFT PANEL — Brand Visual */}
      <div className="al-brand-panel">
        {/* Animated Constellation Canvas */}
        <canvas ref={canvasRef} className="al-canvas-bg" />
        
        {/* Subtle noise layer */}
        <div className="al-noise"></div>

        <div className={`al-brand-content ${mounted ? 'al-visible' : ''}`}>
          <div className="al-brand-badge">
            <span className="al-brand-badge-dot"></span>
            <span>Executive Management</span>
          </div>

          <h1 className="al-brand-title">
            Kenick Transportation<br />
            <span>Command Center</span>
          </h1>
          <p className="al-brand-desc">
            Full platform governance. Monitor journeys, orchestrate chauffeurs, 
            audit financial ledgers, and manage clientele services in real-time.
          </p>

          <div className="al-brand-stats">
            <div className="al-stat-card">
              <span className="al-stat-value">24/7</span>
              <span className="al-stat-label">Telemetry</span>
            </div>
            <div className="al-stat-card">
              <span className="al-stat-value">100%</span>
              <span className="al-stat-label">Encrypted</span>
            </div>
            <div className="al-stat-card">
              <span className="al-stat-value">Real-time</span>
              <span className="al-stat-label">Analytics</span>
            </div>
          </div>

          <div className="al-brand-guarantee">
            <ShieldCheck size={16} color="var(--admin-primary, #F4C522)" />
            <span>Authorized administrative credentials required</span>
          </div>
        </div>
      </div>

      {/* RIGHT PANEL — Login Form */}
      <div className="al-form-panel">
        <div className={`al-form-container ${mounted ? 'al-visible' : ''}`}>
          <div className="al-form-header">
            <h2>Welcome back</h2>
            <p>Enter your executive credentials to access the command center</p>
          </div>

          {error && (
            <div className="al-error">
              <AlertCircle size={16} style={{ flexShrink: 0 }} />
              <span>{error}</span>
            </div>
          )}

          <form className="al-form" onSubmit={handleLogin}>
            {/* Email Field */}
            <div className="al-field">
              <label htmlFor="al-email">Email address</label>
              <div className="al-input-wrap">
                <Mail size={16} className="al-input-icon" />
                <input
                  id="al-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@kenick.com"
                  autoComplete="email"
                  required
                />
              </div>
            </div>

            {/* Password Field */}
            <div className="al-field">
              <label htmlFor="al-password">Password</label>
              <div className="al-input-wrap al-password-wrap">
                <Lock size={16} className="al-input-icon" />
                <input
                  id="al-password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  className="al-eye-btn"
                  onClick={() => setShowPassword(!showPassword)}
                  tabIndex={-1}
                  title={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            {/* Submit */}
            <button type="submit" className="al-submit" disabled={submitting}>
              {submitting ? (
                <div className="al-loader">
                  <div className="al-loader-bar"></div>
                </div>
              ) : (
                <>
                  <span>Sign in to Dashboard</span>
                  <ArrowRight size={17} />
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
