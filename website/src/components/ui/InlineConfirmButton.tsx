import React, { useState, useEffect } from 'react';

interface InlineConfirmButtonProps {
  label: React.ReactNode;
  confirmLabel?: React.ReactNode;
  onConfirm: () => void;
  className?: string;
  confirmClassName?: string;
  style?: React.CSSProperties;
  title?: string;
  disabled?: boolean;
}

export const InlineConfirmButton: React.FC<InlineConfirmButtonProps> = ({
  label,
  confirmLabel = 'Confirm?',
  onConfirm,
  className = 'admin-btn admin-btn-outline',
  confirmClassName = 'admin-btn admin-btn-danger',
  style,
  title,
  disabled = false,
}) => {
  const [confirming, setConfirming] = useState(false);

  useEffect(() => {
    if (!confirming) return;
    const timer = setTimeout(() => setConfirming(false), 5000);
    return () => clearTimeout(timer);
  }, [confirming]);

  if (confirming) {
    return (
      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, ...style }}>
        <button
          type="button"
          disabled={disabled}
          onClick={(e) => {
            e.stopPropagation();
            setConfirming(false);
            onConfirm();
          }}
          className={confirmClassName}
          style={{ padding: '0.35rem 0.65rem', fontSize: '0.75rem' }}
        >
          {confirmLabel}
        </button>
        <button
          type="button"
          disabled={disabled}
          onClick={(e) => {
            e.stopPropagation();
            setConfirming(false);
          }}
          className="admin-btn admin-btn-outline"
          style={{ padding: '0.35rem 0.55rem', fontSize: '0.75rem' }}
        >
          Cancel
        </button>
      </div>
    );
  }

  return (
    <button
      type="button"
      disabled={disabled}
      title={title}
      onClick={(e) => {
        e.stopPropagation();
        setConfirming(true);
      }}
      className={className}
      style={style}
    >
      {label}
    </button>
  );
};
