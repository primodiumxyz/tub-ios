import React, { useState } from 'react';
import { useTub } from '../hooks/useTub';

export const RegisterPane: React.FC = () => {
  const [username, setUsername] = useState('');
  const { register } = useTub();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    register(username);
  };

  return (
    <div className= "w-screen h-screen flex items-center justify-center ">
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
        placeholder="Enter username"
        className="border border-gray-300 rounded-md p-2 mr-2"
      />
      <button type="submit" className="bg-blue-500 text-white rounded-md p-2">Register</button>
    </form>
</div>
  );
};
