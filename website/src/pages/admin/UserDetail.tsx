import { useParams } from 'react-router-dom';

export default function UserDetail() {
  const { id } = useParams();

  return (
    <div className="admin-card">
      <h2 className="text-xl font-bold mb-4">User Details</h2>
      <p className="text-zinc-400">Viewing details for user ID: {id}</p>
    </div>
  );
}
