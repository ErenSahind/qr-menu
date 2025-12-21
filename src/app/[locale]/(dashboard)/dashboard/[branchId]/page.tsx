export default function BranchOverview({
  params,
}: {
  params: { branchId: string };
}) {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Şube Paneli</h1>
      <p className="text-gray-600">Şube ID: {params.branchId}</p>

      <div className="mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="font-bold text-lg mb-2">QR Kodlar</h3>
          <p className="text-gray-500 mb-4">
            Masalarınız için QR kodları yönetin.
          </p>
          <a
            href={`/dashboard/${params.branchId}/qr-management`}
            className="text-blue-600 hover:underline"
          >
            Yönet &rarr;
          </a>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="font-bold text-lg mb-2">Menü</h3>
          <p className="text-gray-500 mb-4">
            Ürünlerinizi ve kategorilerinizi düzenleyin.
          </p>
          <a href="#" className="text-blue-600 hover:underline">
            Düzenle &rarr;
          </a>
        </div>
      </div>
    </div>
  );
}
