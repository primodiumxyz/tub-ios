import React, { useState, useRef, useEffect } from 'react';

interface SliderProps {
  onSlideComplete: () => void;
  text?: string;
  disabled?: boolean;
}

const Slider: React.FC<SliderProps> = ({ onSlideComplete, text = "slide to unlock", disabled = false }) => {
  const [sliderPosition, setSliderPosition] = useState(0);
  const [slideComplete, setSlideComplete] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const sliderRef = useRef<HTMLDivElement>(null);
  const thumbRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (disabled) return;

    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging) return;
      const sliderRect = sliderRef.current?.getBoundingClientRect();
      const thumbRect = thumbRef.current?.getBoundingClientRect();
      if (!sliderRect || !thumbRect) return;

      const thumbWidth = thumbRect.width;
      const newPosition = Math.max(0, Math.min(e.clientX - sliderRect.left - thumbWidth / 2, sliderRect.width - thumbWidth));
      setSliderPosition(newPosition);

      if (newPosition >= sliderRect.width - thumbWidth ) {
        setIsDragging(false);
        setSlideComplete(true);
        // Add a short pause before calling onSlideComplete
        setTimeout(() => {
          onSlideComplete();
        }, 300); // 300ms delay
      }
    };

    const handleMouseUp = () => {
      if (isDragging) {
        setIsDragging(false);
        setSliderPosition(0);
      }
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging, onSlideComplete, disabled]);

  return (
    <div 
      ref={sliderRef}
      className={`relative w-64 h-12 bg-gray-200 rounded-full overflow-hidden ${disabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer'}`}
    >
      <div 
        className="pointer-events-none absolute inset-0 flex items-center justify-center text-gray-500 uppercase tracking-wider select-none"
      >
        {slideComplete ? "Success!" : text}
      </div>
      <div
        ref={thumbRef}
        className={`absolute top-0 left-0 w-12 h-12 bg-white rounded-full shadow-md flex items-center justify-center transition-transform duration-300 ease-out ${disabled ? 'cursor-not-allowed' : ''}`}
        style={{ transform: `translateX(${sliderPosition}px)` }}
        onMouseDown={() => !disabled && setIsDragging(true)}
      >
        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
      </div>
    </div>
  );
};

export default Slider;
