import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Home, MessageCircle } from 'lucide-react';

export function Footer() {
  const navigate = useNavigate();
  const location = useLocation();

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200">
      <div className="max-w-screen-xl mx-auto px-4">
        <div className="flex justify-end items-center h-16 space-x-4">
          <button
            onClick={() => navigate('/chat')}
            className={`p-3 rounded-full ${
              location.pathname === '/chat'
                ? 'bg-green-100 text-green-600'
                : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            <MessageCircle className="w-6 h-6" />
          </button>
          <button
            onClick={() => navigate('/')}
            className={`p-3 rounded-full ${
              location.pathname === '/'
                ? 'bg-green-100 text-green-600'
                : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            <Home className="w-6 h-6" />
          </button>
        </div>
      </div>
    </div>
  );
}