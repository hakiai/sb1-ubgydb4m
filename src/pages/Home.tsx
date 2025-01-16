import React from 'react';
import { supabase } from '../lib/supabase';
import { User } from 'lucide-react';

interface Profile {
  id: string;
  username: string | null;
  avatar_url: string | null;
  email: string | null;
}

export function Home() {
  const [profile, setProfile] = React.useState<Profile | null>(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        setLoading(false);
        return;
      }

      // プロフィールの読み込みを試みる
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('id, username, avatar_url, email')
        .eq('id', session.user.id)
        .maybeSingle();

      if (!profileData && (!profileError || profileError.code === 'PGRST116')) {
        // プロフィールが存在しない場合、新しく作成
        await supabase.rpc('handle_new_user', { 
          user_id: session.user.id,
          user_email: session.user.email
        });

        // 作成したプロフィールを再度読み込む
        const { data: newProfile } = await supabase
          .from('profiles')
          .select('id, username, avatar_url, email')
          .eq('id', session.user.id)
          .single();

        if (newProfile) {
          setProfile(newProfile);
        }
      } else if (profileData) {
        setProfile(profileData);
      }
    } catch (error) {
      console.error('エラー:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-green-500 border-t-transparent rounded-full animate-spin mx-auto"></div>
          <p className="mt-4 text-gray-600">読み込み中...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 pb-20">
      <div className="max-w-screen-xl mx-auto px-4 py-8">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center space-x-4 mb-6">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
              <User className="w-8 h-8 text-green-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                {profile?.username || 'ユーザー'}
              </h1>
              <p className="text-gray-600">{profile?.email}</p>
            </div>
          </div>
          <div className="space-y-4">
            <button
              onClick={handleSignOut}
              className="w-full bg-red-500 text-white py-2 px-4 rounded-lg hover:bg-red-600 transition-colors"
            >
              ログアウト
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}