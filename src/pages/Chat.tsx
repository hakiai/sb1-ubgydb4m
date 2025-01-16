import React from 'react';
import {
  MessageCircle,
  Send,
  Menu,
  Phone,
  Video,
  Plus,
  Smile,
  X,
} from 'lucide-react';
import { supabase } from '../lib/supabase';

interface Message {
  id: string;
  text: string;
  is_sent: boolean;
  created_at: string;
  user_id: string;
  room_id: string;
  is_ai_response?: boolean;
  ai_response?: string;
}

interface ChatRoom {
  id: string;
  name: string;
  created_at: string;
  created_by: string;
}

interface Profile {
  id: string;
  username: string;
  avatar_url: string;
}

export function Chat() {
  const [messages, setMessages] = React.useState<Message[]>([]);
  const [newMessage, setNewMessage] = React.useState('');
  const [session, setSession] = React.useState<any>(null);
  const [isMenuOpen, setIsMenuOpen] = React.useState(false);
  const [isNewChatDialogOpen, setIsNewChatDialogOpen] = React.useState(false);
  const [newRoomName, setNewRoomName] = React.useState('');
  const [selectedUserId, setSelectedUserId] = React.useState('');
  const [chatRooms, setChatRooms] = React.useState<ChatRoom[]>([]);
  const [currentRoomId, setCurrentRoomId] = React.useState<string | null>(null);
  const [friends, setFriends] = React.useState<Profile[]>([]);
  const messagesEndRef = React.useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  React.useEffect(() => {
    scrollToBottom();
  }, [messages]);

  React.useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);

  React.useEffect(() => {
    if (session) {
      loadChatRooms();
      loadFriends();

      const roomsSubscription = supabase
        .channel('chat_rooms')
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'chat_rooms',
          },
          () => {
            loadChatRooms();
          }
        )
        .subscribe();

      return () => {
        supabase.removeChannel(roomsSubscription);
      };
    }
  }, [session]);

  React.useEffect(() => {
    if (session && currentRoomId) {
      loadMessages(currentRoomId);

      const messagesSubscription = supabase
        .channel(`messages:${currentRoomId}`)
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'messages',
            filter: `room_id=eq.${currentRoomId}`,
          },
          (payload) => {
            const newMessage = payload.new as Message;
            setMessages((prev) => {
              // 重複を避けるために既存のメッセージをチェック
              const messageExists = prev.some(
                (msg) => msg.id === newMessage.id
              );
              if (messageExists) {
                return prev;
              }
              return [...prev, newMessage];
            });
            scrollToBottom();
          }
        )
        .subscribe();

      return () => {
        supabase.removeChannel(messagesSubscription);
      };
    }
  }, [session, currentRoomId]);

  const loadFriends = async () => {
    if (!session) return;

    try {
      const { data: acceptedFriends, error: acceptedError } = await supabase
        .from('friendships')
        .select(
          `
          id,
          friend:profiles!friendships_friend_id_fkey (
            id,
            username,
            avatar_url
          )
        `
        )
        .eq('user_id', session.user.id)
        .eq('status', 'accepted');

      if (acceptedError) throw acceptedError;
      setFriends(acceptedFriends?.map((f) => f.friend) || []);
    } catch (error) {
      console.error('フレンド一覧の読み込みエラー:', error);
    }
  };

  const loadChatRooms = async () => {
    try {
      const { data, error } = await supabase
        .from('chat_rooms')
        .select(
          `
          *,
          chat_room_members!inner(user_id)
        `
        )
        .eq('chat_room_members.user_id', session.user.id);

      if (error) throw error;
      setChatRooms(data || []);
    } catch (error) {
      console.error('チャットルームの読み込みエラー:', error);
    }
  };

  const loadMessages = async (roomId: string) => {
    try {
      const { data, error } = await supabase
        .from('messages')
        .select('*')
        .eq('room_id', roomId)
        .order('created_at', { ascending: true });

      if (error) throw error;
      setMessages(data || []);
      scrollToBottom();
    } catch (error) {
      console.error('メッセージの読み込みエラー:', error);
    }
  };

  const createChatRoom = async () => {
    if (!newRoomName.trim() || !selectedUserId) return;

    try {
      const { data: roomData, error: roomError } = await supabase
        .from('chat_rooms')
        .insert([
          {
            name: newRoomName,
            created_by: session.user.id,
          },
        ])
        .select()
        .single();

      if (roomError) throw roomError;

      const { error: membersError } = await supabase
        .from('chat_room_members')
        .insert([
          { room_id: roomData.id, user_id: session.user.id },
          { room_id: roomData.id, user_id: selectedUserId },
        ]);

      if (membersError) throw membersError;

      setIsNewChatDialogOpen(false);
      setNewRoomName('');
      setSelectedUserId('');
      setCurrentRoomId(roomData.id);
    } catch (error) {
      console.error('チャットルーム作成エラー:', error);
    }
  };

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || !session?.user || !currentRoomId) return;

    try {
      const messageData = {
        text: newMessage,
        user_id: session.user.id,
        room_id: currentRoomId,
        is_sent: true,
      };

      // ユーザーメッセージを送信
      const { data: userMessage, error: userMessageError } = await supabase
        .from('messages')
        .insert([messageData])
        .select()
        .single();

      if (userMessageError) throw userMessageError;

      // AI応答を生成
      const { data: aiMessage, error: aiMessageError } = await supabase
        .rpc('generate_ai_response', { message_text: newMessage })
        .single();

      if (aiMessageError) throw aiMessageError;

      // AI応答メッセージを保存
      if (aiMessage) {
        const aiMessageData = {
          text: aiMessage,
          user_id: session.user.id,
          room_id: currentRoomId,
          is_sent: true,
          is_ai_response: true,
          ai_response: aiMessage,
        };

        await supabase.from('messages').insert([aiMessageData]);
      }

      setNewMessage('');
    } catch (error) {
      console.error('メッセージ送信エラー:', error);
    }
  };

  if (!session) {
    return null;
  }

  return (
    <div className="flex h-screen bg-gray-100 pb-16">
      {/* Left Sidebar */}
      <div className="w-80 bg-white border-r border-gray-200">
        <div className="p-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-bold">チャットtest</h1>
            <div className="relative">
              <button
                onClick={() => setIsMenuOpen(!isMenuOpen)}
                className="p-2 hover:bg-gray-100 rounded-full"
              >
                <Menu className="w-6 h-6 text-gray-600" />
              </button>
              {isMenuOpen && (
                <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg py-1 z-10">
                  <button
                    onClick={() => {
                      setIsNewChatDialogOpen(true);
                      setIsMenuOpen(false);
                    }}
                    className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  >
                    新しいチャットを始める
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Chat List */}
        <div className="overflow-y-auto">
          {chatRooms.map((room) => (
            <div
              key={room.id}
              onClick={() => setCurrentRoomId(room.id)}
              className={`p-4 hover:bg-gray-50 cursor-pointer border-b border-gray-100 ${
                currentRoomId === room.id ? 'bg-gray-50' : ''
              }`}
            >
              <div className="flex items-center">
                <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                  <MessageCircle className="w-6 h-6 text-green-600" />
                </div>
                <div className="ml-4">
                  <div className="font-semibold">{room.name}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col">
        {currentRoomId ? (
          <>
            {/* Chat Header */}
            <div className="bg-white p-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                    <MessageCircle className="w-5 h-5 text-green-600" />
                  </div>
                  <span className="ml-3 font-semibold">
                    {chatRooms.find((room) => room.id === currentRoomId)?.name}
                  </span>
                </div>
                <div className="flex items-center space-x-4">
                  <Phone className="w-5 h-5 text-gray-600 cursor-pointer" />
                  <Video className="w-5 h-5 text-gray-600 cursor-pointer" />
                  <MessageCircle className="w-5 h-5 text-gray-600 cursor-pointer" />
                </div>
              </div>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50">
              {messages.map((message) => (
                <div
                  key={message.id}
                  className={`flex ${
                    message.user_id === session.user.id
                      ? 'justify-end'
                      : 'justify-start'
                  }`}
                >
                  <div
                    className={`max-w-[70%] rounded-lg p-3 ${
                      message.is_ai_response
                        ? 'bg-blue-500 text-white'
                        : message.user_id === session.user.id
                        ? 'bg-green-500 text-white'
                        : 'bg-white border border-gray-200'
                    }`}
                  >
                    <p>{message.text}</p>
                    <p
                      className={`text-xs mt-1 ${
                        message.is_ai_response
                          ? 'text-blue-100'
                          : message.user_id === session.user.id
                          ? 'text-green-100'
                          : 'text-gray-500'
                      }`}
                    >
                      {message.is_ai_response
                        ? 'AI'
                        : new Date(message.created_at).toLocaleTimeString([], {
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                    </p>
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>

            {/* Message Input */}
            <form
              onSubmit={sendMessage}
              className="bg-white p-4 border-t border-gray-200"
            >
              <div className="flex items-center space-x-2">
                <Plus className="w-6 h-6 text-gray-600 cursor-pointer" />
                <input
                  type="text"
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  placeholder="メッセージを入力"
                  className="flex-1 p-2 border border-gray-300 rounded-full focus:outline-none focus:border-green-500"
                />
                <Smile className="w-6 h-6 text-gray-600 cursor-pointer" />
                <button
                  type="submit"
                  className="bg-green-500 text-white p-2 rounded-full hover:bg-green-600 focus:outline-none"
                >
                  <Send className="w-5 h-5" />
                </button>
              </div>
            </form>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center bg-gray-50">
            <div className="text-center">
              <MessageCircle className="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500">チャットルームを選択してください</p>
            </div>
          </div>
        )}
      </div>

      {/* New Chat Dialog */}
      {isNewChatDialogOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
          <div className="bg-white rounded-lg p-6 w-96">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold">新しいチャットを始める</h2>
              <button
                onClick={() => setIsNewChatDialogOpen(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  ルーム名
                </label>
                <input
                  type="text"
                  value={newRoomName}
                  onChange={(e) => setNewRoomName(e.target.value)}
                  className="w-full p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                  placeholder="ルーム名を入力"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  チャットする相手
                </label>
                <select
                  value={selectedUserId}
                  onChange={(e) => setSelectedUserId(e.target.value)}
                  className="w-full p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                >
                  <option value="">選択してください</option>
                  {friends.map((friend) => (
                    <option key={friend.id} value={friend.id}>
                      {friend.username || friend.id}
                    </option>
                  ))}
                </select>
              </div>
              <button
                onClick={createChatRoom}
                className="w-full bg-green-500 text-white py-2 rounded-lg hover:bg-green-600 focus:outline-none"
              >
                チャットを作成
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
