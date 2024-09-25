import React, { useState, useEffect } from 'react';
import ReactDOM from 'react-dom';

interface ToastProps {
  message: string;
  duration?: number;
}

const Toast: React.FC<ToastProps> = ({ message, duration = 100000 }) => {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(false);
    }, duration);

    return () => clearTimeout(timer);
  }, [duration]);

  if (!isVisible) return null;

  return (
    <div
      className="absolute top-0 left-0 w-screen h-screen pointer-events-none"
      
    >
      {message}
    </div>
  );
};


export const toast = (message: string, duration?: number) => {
  ReactDOM.createPortal(
    <Toast message={message} duration={duration} />,
    document.getElementById("toast-container")!,
  );
};

export default Toast;
