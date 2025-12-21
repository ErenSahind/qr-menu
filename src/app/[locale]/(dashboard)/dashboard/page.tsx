import Link from "next/link";

export default function DashboardHome() {
  // Burada kullanıcının şubelerini listeleyeceğiz
  const branches = [
    { id: "1", name: "Kadıköy Şubesi", slug: "kadikoy" },
    { id: "2", name: "Beşiktaş Şubesi", slug: "besiktas" },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Şubelerim</h1>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {branches.map((branch) => (
          <Link
            key={branch.id}
            href={`/dashboard/${branch.id}`}
            className="block p-6 bg-white rounded-lg shadow hover:shadow-md transition-shadow"
          >
            <h2 className="text-xl font-semibold mb-2">{branch.name}</h2>
            <p className="text-gray-500 text-sm">/{branch.slug}</p>
          </Link>
        ))}

        <button className="flex items-center justify-center p-6 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-500 hover:text-blue-500 transition-colors">
          + Yeni Şube Ekle
        </button>
      </div>
    </div>
  );
}
