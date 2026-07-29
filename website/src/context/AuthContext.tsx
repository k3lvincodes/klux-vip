import { createContext, useContext, useEffect, useRef, useState } from 'react';
import type { User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

interface AuthContextType {
  user: User | null;
  isSuperAdmin: boolean;
  loading: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  isSuperAdmin: false,
  loading: true,
  signOut: async () => {},
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  const [loading, setLoading] = useState(true);
  const checkIdRef = useRef(0);

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        checkSuperAdmin(session.user.id);
      } else {
        setIsSuperAdmin(false);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const checkSuperAdmin = async (userId: string) => {
    const id = ++checkIdRef.current;
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('is_super_admin')
        .eq('id', userId)
        .maybeSingle();
      
      if (error) throw error;
      if (id !== checkIdRef.current) return;
      setIsSuperAdmin(data?.is_super_admin ?? false);
    } catch (err) {
      setIsSuperAdmin(false);
    } finally {
      setLoading(false);
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
  };

  return (
    <AuthContext.Provider value={{ user, isSuperAdmin, loading, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};
